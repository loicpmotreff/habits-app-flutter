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
      // Vérification du changement de jour
      if (habit.lastCompletedDate != null) {
        bool isSameDay = habit.lastCompletedDate!.year == now.year &&
            habit.lastCompletedDate!.month == now.month &&
            habit.lastCompletedDate!.day == now.day;
        
        if (!isSameDay) {
          // C'EST UN NOUVEAU JOUR !
          if (habit.isNegative) {
             // Si c'est une habitude négative, elle commence VALIDÉE (On suppose qu'on a tenu bon)
             // L'utilisateur devra la décocher s'il craque.
             habit.isCompletedToday = true;
             habit.currentValue = habit.targetValue; // Visuellement rempli
          } else {
             // Habitude classique : remise à zéro
             habit.isCompletedToday = false;
             habit.currentValue = 0;
          }
          habit.save();
        }
      } else {
        // Cas spécial : Première création ou jamais touché
        // Si on crée une habitude négative aujourd'hui, elle devrait être valide par défaut ? 
        // Pour l'instant on laisse l'utilisateur la cocher la première fois pour activer le cycle.
      }
    }
    habits = allHabits.where((habit) => habit.activeDays.contains(now.weekday)).toList();
    notifyListeners();
  }

  // AJOUTER (Avec isNegative)
  void addHabit(String title, List<int> days, HabitDifficulty difficulty, HabitCategory category, int targetValue, String unit, bool isTimer, bool isNegative) {
    // Si c'est négatif, on la considère comme faite par défaut à la création (on part du principe que tu n'as pas encore craqué)
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
      currentValue: startCompleted ? targetValue : 0, // Rempli si négatif
      unit: unit,
      isTimer: isTimer,
      isNegative: isNegative, // <--- NOUVEAU
      isCompletedToday: startCompleted, 
      lastCompletedDate: DateTime.now(), // On marque la date pour le reset de demain
    );
    final box = Hive.box<Habit>(boxName);
    box.add(newHabit);
    loadHabits();
  }

  // MODIFIER (Avec isNegative)
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
      habit.isNegative = isNegative; // <--- UPDATE
      habit.save();
      loadHabits();
    }
  }

  void updateProgress(Habit habit, int change) {
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

    // LOGIQUE DE GAIN / PERTE
    if (isNowCompleted && !habit.isCompletedToday) {
      // ON VIENT DE VALIDER (Ou re-valider)
      habit.isCompletedToday = true;
      habit.lastCompletedDate = DateTime.now();
      
      // Si c'est négatif, ça veut dire qu'on a "réparé" son erreur (on a recoché la case)
      // On ne gagne pas de streak supplémentaire si on fait juste le yoyo, mais on récupère son état.
      if (!habit.isNegative) habit.streak++;

      int reward = 10;
      if (habit.difficulty == HabitDifficulty.easy) reward = 5;
      if (habit.difficulty == HabitDifficulty.hard) reward = 20;
      updateScore(reward);

      if (!habit.completedDays.contains(todayNormalized)) {
        habit.completedDays.add(todayNormalized);
      }

    } 
    else if (!isNowCompleted && habit.isCompletedToday) {
      // ON VIENT D'ANNULER (Ou de craquer pour une négative)
      habit.isCompletedToday = false;
      
      // Si c'est une habitude classique, on perd le streak.
      // Si c'est une habitude négative, "décocher" veut dire "J'ai craqué". C'est un échec.
      if (habit.streak > 0) habit.streak--; // On perd un jour de flamme

      int penalty = 10;
      if (habit.difficulty == HabitDifficulty.easy) penalty = 5;
      if (habit.difficulty == HabitDifficulty.hard) penalty = 20;
      updateScore(-penalty); // On perd l'argent

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
    box.put('inventory', inventory);
    box.put('itemActive', itemActive);
  }

  void deleteHabit(Habit habit) {
    habit.delete();
    loadHabits();
  }
}