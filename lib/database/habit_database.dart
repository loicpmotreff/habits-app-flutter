import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../sound_manager.dart'; // Pour le son du Level Up

class HabitDatabase extends ChangeNotifier {
  static const String boxName = 'habit_box';
  static const String settingsBoxName = 'settings_box';

  List<Habit> habits = [];
  
  // --- NOUVEAUX CHAMPS RPG ---
  int userScore = 0;      // Or (Gold)
  int userLevel = 1;      // Niveau
  int currentXP = 0;      // XP actuelle
  // ---------------------------

  List<String> inventory = [];
  String itemActive = 'default';

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
    
    // CHARGEMENT XP & NIVEAU
    userLevel = (settingsBox.get('level') ?? 1) as int;
    currentXP = (settingsBox.get('xp') ?? 0) as int;
    
    var rawInventory = settingsBox.get('inventory');
    inventory = rawInventory != null ? List<String>.from(rawInventory) : [];
    itemActive = settingsBox.get('itemActive', defaultValue: 'default');

    loadHabits();
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

  // --- LOGIQUE XP & NIVEAUX ---
  int get xpRequiredForNextLevel => userLevel * 100; // Niv 1 = 100xp, Niv 2 = 200xp...

  void addXP(int amount) {
    currentXP += amount;

    // Montée de niveau (Level Up)
    while (currentXP >= xpRequiredForNextLevel) {
      currentXP -= xpRequiredForNextLevel;
      userLevel++;
      SoundManager.play('success.mp3'); // Son de victoire à chaque niveau !
    }

    // Descente de niveau (Si on décoche des tâches et qu'on passe en négatif)
    while (currentXP < 0 && userLevel > 1) {
      userLevel--;
      currentXP += xpRequiredForNextLevel; // On récupère le max XP du niveau précédent
    }
    // Si niveau 1 et XP négative, on bloque à 0
    if (userLevel == 1 && currentXP < 0) currentXP = 0;

    updateSettings();
  }
  // ----------------------------

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

    // --- MISE À JOUR SCORE ET XP ---
    if (isNowCompleted && !habit.isCompletedToday) {
      habit.isCompletedToday = true;
      habit.lastCompletedDate = DateTime.now();
      if (!habit.isNegative) habit.streak++;

      // CALCUL RÉCOMPENSE
      int baseReward = 10;
      if (habit.difficulty == HabitDifficulty.easy) baseReward = 5;
      if (habit.difficulty == HabitDifficulty.hard) baseReward = 20;
      
      updateScore(baseReward); // OR
      addXP(baseReward);       // XP (Même montant que l'or pour simplifier)

      if (!habit.completedDays.contains(todayNormalized)) {
        habit.completedDays.add(todayNormalized);
      }
    } 
    else if (!isNowCompleted && habit.isCompletedToday) {
      habit.isCompletedToday = false;
      if (habit.streak > 0) habit.streak--; 

      // CALCUL PÉNALITÉ
      int basePenalty = 10;
      if (habit.difficulty == HabitDifficulty.easy) basePenalty = 5;
      if (habit.difficulty == HabitDifficulty.hard) basePenalty = 20;
      
      updateScore(-basePenalty); // PERTE OR
      addXP(-basePenalty);       // PERTE XP

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
    box.put('level', userLevel); // Sauvegarde Niveau
    box.put('xp', currentXP);    // Sauvegarde XP
    box.put('inventory', inventory);
    box.put('itemActive', itemActive);
  }

  void deleteHabit(Habit habit) {
    habit.delete();
    loadHabits();
  }
}