import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

class HabitDatabase extends ChangeNotifier {
  static const String boxName = 'habit_box';
  static const String settingsBoxName = 'settings_box';

  List<Habit> habits = [];
  int userScore = 0;
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
    var rawInventory = settingsBox.get('inventory');
    inventory = rawInventory != null ? List<String>.from(rawInventory) : [];
    itemActive = settingsBox.get('itemActive', defaultValue: 'default');

    loadHabits();
  }

  void loadHabits() {
    final box = Hive.box<Habit>(boxName);
    final allHabits = box.values.toList();
    final now = DateTime.now();

    for (var habit in allHabits) {
      if (habit.lastCompletedDate != null) {
        bool isSameDay = habit.lastCompletedDate!.year == now.year &&
            habit.lastCompletedDate!.month == now.month &&
            habit.lastCompletedDate!.day == now.day;
        
        if (!isSameDay) {
          habit.isCompletedToday = false;
          habit.currentValue = 0;
          habit.save();
        }
      }
    }
    habits = allHabits.where((habit) => habit.activeDays.contains(now.weekday)).toList();
    notifyListeners();
  }

  // AJOUTER (Avec isTimer)
  void addHabit(String title, List<int> days, HabitDifficulty difficulty, HabitCategory category, int targetValue, String unit, bool isTimer) {
    final newHabit = Habit(
      id: DateTime.now().toString(),
      title: title,
      streak: 0,
      activeDays: days,
      completedDays: [],
      difficulty: difficulty,
      category: category,
      targetValue: targetValue,
      currentValue: 0,
      unit: unit,
      isTimer: isTimer, // <--- NOUVEAU
    );
    final box = Hive.box<Habit>(boxName);
    box.add(newHabit);
    loadHabits();
  }

  // MODIFIER (Avec isTimer)
  void updateHabit(String id, String newTitle, List<int> newDays, HabitDifficulty newDifficulty, HabitCategory newCategory, int newTargetValue, String newUnit, bool isTimer) {
    final habitIndex = habits.indexWhere((h) => h.id == id);
    if (habitIndex != -1) {
      final habit = habits[habitIndex];
      habit.title = newTitle;
      habit.activeDays = newDays;
      habit.difficulty = newDifficulty;
      habit.category = newCategory;
      habit.targetValue = newTargetValue;
      habit.unit = newUnit;
      habit.isTimer = isTimer; // <--- UPDATE
      habit.save();
      loadHabits();
    }
  }

  void updateProgress(Habit habit, int change) {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    // Si c'est un timer, targetValue est en minutes, mais on gère la validation directement.
    // Cette fonction sert surtout pour les compteurs et checkboxes.
    
    int newValue = habit.currentValue + change;
    if (newValue < 0) newValue = 0;
    // Note : Pour le timer, on ne bloque pas newValue ici car on s'en sert différemment
    if (!habit.isTimer && newValue > habit.targetValue) newValue = habit.targetValue;
    
    habit.currentValue = newValue;
    
    // Logique de complétion
    bool isNowCompleted;
    if (habit.isTimer) {
      // Pour le timer, c'est l'UI qui dira "C'est fini" en appelant cette fonction avec une valeur spéciale ou manuellement
      // Ici on simplifie : si on appelle updateProgress sur un timer terminé, on considère que c'est bon
      isNowCompleted = habit.currentValue >= 1; // 1 = Timer Fini
    } else {
      isNowCompleted = habit.currentValue >= habit.targetValue;
    }

    if (isNowCompleted && !habit.isCompletedToday) {
      habit.isCompletedToday = true;
      habit.lastCompletedDate = DateTime.now();
      habit.streak++;

      int reward = 10;
      if (habit.difficulty == HabitDifficulty.easy) reward = 5;
      if (habit.difficulty == HabitDifficulty.hard) reward = 20;
      updateScore(reward);

      if (!habit.completedDays.contains(todayNormalized)) {
        habit.completedDays.add(todayNormalized);
      }
    } 
    else if (!isNowCompleted && habit.isCompletedToday) {
      habit.isCompletedToday = false;
      habit.streak = (habit.streak > 0) ? habit.streak - 1 : 0;

      int penalty = 10;
      if (habit.difficulty == HabitDifficulty.easy) penalty = 5;
      if (habit.difficulty == HabitDifficulty.hard) penalty = 20;
      updateScore(-penalty);

      habit.completedDays.removeWhere((date) => 
        date.year == today.year && date.month == today.month && date.day == today.day
      );
    }
    habit.save();
    notifyListeners();
  }

  // --- Force la validation (Pour le Timer quand il arrive à 0) ---
  void completeHabit(Habit habit) {
    if (!habit.isCompletedToday) {
      habit.currentValue = habit.targetValue; // On met au max visuellement
      updateProgress(habit, 0); // Déclenche la logique de gain
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
    box.put('inventory', inventory);
    box.put('itemActive', itemActive);
  }

  void deleteHabit(Habit habit) {
    habit.delete();
    loadHabits();
  }
}