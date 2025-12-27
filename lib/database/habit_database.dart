import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

class HabitDatabase extends ChangeNotifier {
  static const String boxName = 'habit_box';
  static const String settingsBoxName = 'settings_box';

  List<Habit> habits = [];
  int userScore = 0;

  // Inventaire
  List<String> inventory = [];
  String itemActive = 'default';

  Future<void> init() async {
    await Hive.initFlutter();
    // On enregistre les deux adaptateurs
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitDifficultyAdapter()); // Pour gérer la difficulté

    // SÉCURITÉ : Si la base de données est incompatible, on réinitialise
    try {
      await Hive.openBox<Habit>(boxName);
    } catch (e) {
      print("Erreur détectée : Reset de la base...");
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<Habit>(boxName);
    }

    var settingsBox = await Hive.openBox(settingsBoxName);

    // Chargement sécurisé du score
    userScore = (settingsBox.get('score') ?? 0) as int;

    // Chargement sécurisé de l'inventaire
    var rawInventory = settingsBox.get('inventory');
    if (rawInventory != null) {
      inventory = List<String>.from(rawInventory);
    } else {
      inventory = [];
    }

    itemActive = settingsBox.get('itemActive', defaultValue: 'default');

    loadHabits();
  }

  void loadHabits() {
    final box = Hive.box<Habit>(boxName);
    final allHabits = box.values.toList();
    final now = DateTime.now();

    // 1. Reset si ce n'est plus le même jour
    for (var habit in allHabits) {
      if (habit.lastCompletedDate != null) {
        bool isSameDay = habit.lastCompletedDate!.year == now.year &&
            habit.lastCompletedDate!.month == now.month &&
            habit.lastCompletedDate!.day == now.day;
        if (!isSameDay) {
          habit.isCompletedToday = false;
          habit.save();
        }
      }
    }

    // 2. FILTRE : On ne garde que les habitudes prévues pour AUJOURD'HUI
    habits = allHabits.where((habit) {
      return habit.activeDays.contains(now.weekday);
    }).toList();

    notifyListeners();
  }

  // AJOUTER UNE HABITUDE (Avec la difficulté)
  void addHabit(String title, List<int> days, HabitDifficulty difficulty) {
    final newHabit = Habit(
      id: DateTime.now().toString(),
      title: title,
      streak: 0,
      activeDays: days,
      completedDays: [],
      difficulty: difficulty, // On stocke la difficulté choisie
    );
    final box = Hive.box<Habit>(boxName);
    box.add(newHabit);
    loadHabits();
  }

  // MODIFIER UNE HABITUDE (Avec la difficulté)
  void updateHabit(String id, String newTitle, List<int> newDays, HabitDifficulty newDifficulty) {
    final habitIndex = habits.indexWhere((h) => h.id == id);
    if (habitIndex != -1) {
      final habit = habits[habitIndex];
      habit.title = newTitle;
      habit.activeDays = newDays;
      habit.difficulty = newDifficulty; // Mise à jour de la difficulté
      habit.save();
      loadHabits();
    }
  }

  // COCHER / DÉCOCHER (Avec calcul intelligent des gains)
  void toggleHabit(Habit habit) {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    habit.isCompletedToday = !habit.isCompletedToday;

    if (habit.isCompletedToday) {
      // ✅ Si on coche : On gagne des pièces selon la difficulté
      habit.lastCompletedDate = DateTime.now();
      habit.streak++;

      // CALCUL DU PRIX
      int reward = 10; // Moyen
      if (habit.difficulty == HabitDifficulty.easy) reward = 5;
      if (habit.difficulty == HabitDifficulty.hard) reward = 20;

      updateScore(reward);

      // On ajoute la date à l'historique
      if (!habit.completedDays.contains(todayNormalized)) {
        habit.completedDays.add(todayNormalized);
      }
    } else {
      // ❌ Si on décoche : On perd l'argent
      habit.streak = (habit.streak > 0) ? habit.streak - 1 : 0;

      int penalty = 10;
      if (habit.difficulty == HabitDifficulty.easy) penalty = 5;
      if (habit.difficulty == HabitDifficulty.hard) penalty = 20;

      updateScore(-penalty);

      // C'EST ICI QUE C'ÉTAIT CASSÉ : On retire la date d'aujourd'hui
      habit.completedDays.removeWhere((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day
      );
    }

    habit.save();
    notifyListeners();
  }

  // GESTION SCORE & BOUTIQUE
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