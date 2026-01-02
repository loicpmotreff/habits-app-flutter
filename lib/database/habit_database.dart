import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../sound_manager.dart';

class HabitDatabase extends ChangeNotifier {
  static const String boxName = 'habit_box';
  static const String settingsBoxName = 'settings_box';

  List<Habit> habits = [];
  int userScore = 0;
  int userLevel = 1;
  int currentXP = 0;
  List<String> inventory = [];
  String itemActive = 'default';
  
  // --- NOUVEAU : THÈME ---
  bool isDarkMode = false; 

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitDifficultyAdapter());
    Hive.registerAdapter(HabitCategoryAdapter());

    try {
      await Hive.openBox<Habit>(boxName);
    } catch (e) {
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<Habit>(boxName);
    }

    var settingsBox = await Hive.openBox(settingsBoxName);
    userScore = (settingsBox.get('score') ?? 0) as int;
    userLevel = (settingsBox.get('level') ?? 1) as int;
    currentXP = (settingsBox.get('xp') ?? 0) as int;
    inventory = (settingsBox.get('inventory') != null) ? List<String>.from(settingsBox.get('inventory')) : [];
    itemActive = settingsBox.get('itemActive', defaultValue: 'default');
    
    // Charger le thème
    isDarkMode = settingsBox.get('isDarkMode', defaultValue: false);

    loadHabits();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    updateSettings();
    notifyListeners(); // Dit à l'app de se redessiner
  }

  void loadHabits() {
    final box = Hive.box<Habit>(boxName);
    final allHabits = box.values.toList();
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);

    for (var habit in allHabits) {
      if (habit.lastCompletedDate != null) {
        final lastDate = habit.lastCompletedDate!;
        bool isToday = lastDate.year == now.year && lastDate.month == now.month && lastDate.day == now.day;
        
        if (!isToday) {
           final yesterday = todayNormalized.subtract(const Duration(days: 1));
           bool wasSkippedYesterday = habit.skippedDays.any((d) => 
             d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day
           );
           bool wasCompletedYesterday = lastDate.year == yesterday.year && lastDate.month == yesterday.month && lastDate.day == yesterday.day;

           if (!wasCompletedYesterday && !wasSkippedYesterday) {
              habit.streak = 0;
           }

           if (habit.isNegative) {
             habit.isCompletedToday = true;
             habit.currentValue = habit.targetValue;
           } else {
             habit.isCompletedToday = false;
             habit.currentValue = 0;
           }
           habit.save();
        }
      }
    }
    habits = allHabits.where((habit) => habit.activeDays.contains(now.weekday)).toList();
    notifyListeners();
  }

  bool isHabitSkippedToday(Habit habit) {
    final now = DateTime.now();
    return habit.skippedDays.any((d) => 
      d.year == now.year && d.month == now.month && d.day == now.day
    );
  }

  void toggleSkipHabit(Habit habit) {
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    
    if (isHabitSkippedToday(habit)) {
      habit.skippedDays.removeWhere((d) => 
        d.year == now.year && d.month == now.month && d.day == now.day
      );
    } else {
      habit.skippedDays.add(todayNormalized);
      if (habit.isCompletedToday && !habit.isNegative) {
        updateProgress(habit, -habit.currentValue);
      }
    }
    habit.save();
    notifyListeners();
  }

  int get xpRequiredForNextLevel => userLevel * 100;

  void addXP(int amount) {
    currentXP += amount;
    while (currentXP >= xpRequiredForNextLevel) {
      currentXP -= xpRequiredForNextLevel;
      userLevel++;
      SoundManager.play('success.mp3');
    }
    while (currentXP < 0 && userLevel > 1) {
      userLevel--;
      currentXP += xpRequiredForNextLevel;
    }
    if (userLevel == 1 && currentXP < 0) currentXP = 0;
    updateSettings();
  }

  void addHabit(String title, List<int> days, HabitDifficulty difficulty, HabitCategory category, int targetValue, String unit, bool isTimer, bool isNegative) {
    bool startCompleted = isNegative; 
    final newHabit = Habit(
      id: DateTime.now().toString(),
      title: title,
      streak: 0,
      activeDays: days,
      completedDays: [],
      difficulty: difficulty,
      category: category,
      targetValue: targetValue,
      currentValue: startCompleted ? targetValue : 0,
      unit: unit,
      isTimer: isTimer,
      isNegative: isNegative,
      isCompletedToday: startCompleted, 
      lastCompletedDate: DateTime.now(),
      skippedDays: [],
    );
    final box = Hive.box<Habit>(boxName);
    box.add(newHabit);
    loadHabits();
  }

  void updateHabit(String id, String newTitle, List<int> newDays, HabitDifficulty newDifficulty, HabitCategory newCategory, int newTargetValue, String newUnit, bool isTimer, bool isNegative) {
    final habitIndex = habits.indexWhere((h) => h.id == id);
    if (habitIndex != -1) {
      final habit = habits[habitIndex];
      habit.title = newTitle;
      habit.activeDays = newDays;
      habit.difficulty = newDifficulty;
      habit.category = newCategory;
      habit.targetValue = newTargetValue;
      habit.unit = newUnit;
      habit.isTimer = isTimer;
      habit.isNegative = isNegative;
      habit.save();
      loadHabits();
    }
  }

  void updateProgress(Habit habit, int change) {
    if (isHabitSkippedToday(habit)) return; 
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    int newValue = habit.currentValue + change;
    if (newValue < 0) newValue = 0;
    if (!habit.isTimer && newValue > habit.targetValue) newValue = habit.targetValue;
    
    habit.currentValue = newValue;
    
    bool isNowCompleted;
    if (habit.isTimer) {
      isNowCompleted = habit.currentValue >= 1; 
    } else {
      isNowCompleted = habit.currentValue >= habit.targetValue;
    }

    if (isNowCompleted && !habit.isCompletedToday) {
      habit.isCompletedToday = true;
      habit.lastCompletedDate = DateTime.now();
      if (!habit.isNegative) habit.streak++;

      int baseReward = 10; // Medium par défaut
      updateScore(baseReward);
      addXP(baseReward);

      if (!habit.completedDays.contains(todayNormalized)) {
        habit.completedDays.add(todayNormalized);
      }
    } 
    else if (!isNowCompleted && habit.isCompletedToday) {
      habit.isCompletedToday = false;
      if (habit.streak > 0) habit.streak--; 

      int basePenalty = 10;
      updateScore(-basePenalty);
      addXP(-basePenalty);

      habit.completedDays.removeWhere((date) => 
        date.year == today.year && date.month == today.month && date.day == today.day
      );
    }
    habit.save();
    notifyListeners();
  }

  void completeHabit(Habit habit) {
    if (!habit.isCompletedToday) {
      habit.currentValue = habit.targetValue; 
      updateProgress(habit, 0); 
    }
  }

  void updateScore(int amount) {
    userScore += amount;
    if (userScore < 0) userScore = 0;
    updateSettings();
  }
  
  bool buyItem(String itemId, int price) {
    if (inventory.contains(itemId)) return true;
    if (userScore >= price) {
      userScore -= price;
      inventory.add(itemId);
      updateSettings();
      notifyListeners();
      return true;
    }
    return false;
  }

  void setItemActive(String itemId) {
    itemActive = itemId;
    updateSettings();
    notifyListeners();
  }

  void updateSettings() {
    var box = Hive.box(settingsBoxName);
    box.put('score', userScore);
    box.put('level', userLevel);
    box.put('xp', currentXP);
    box.put('inventory', inventory);
    box.put('itemActive', itemActive);
    box.put('isDarkMode', isDarkMode); // <--- Sauvegarde du thème
  }

  void deleteHabit(Habit habit) {
    habit.delete();
    loadHabits();
  }
}