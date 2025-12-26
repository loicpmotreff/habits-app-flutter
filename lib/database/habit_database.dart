import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

class HabitDatabase extends ChangeNotifier {
  static const String boxName = 'habit_box';
  static const String settingsBoxName = 'settings_box'; // Pour stocker l'argent

  List<Habit> habits = [];
  int userScore = 0; // 🪙 Ton argent / XP

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(HabitAdapter());
    
    await Hive.openBox<Habit>(boxName);
    var settingsBox = await Hive.openBox(settingsBoxName);
    
    // Charger le score sauvegardé (0 par défaut)
    userScore = settingsBox.get('score', defaultValue: 0);

    loadHabits();
  }

  void loadHabits() {
    final box = Hive.box<Habit>(boxName);
    habits = box.values.toList();

    // Reset journalier (si on change de jour)
    final now = DateTime.now();
    for (var habit in habits) {
      if (habit.lastCompletedDate != null) {
        bool isSameDay = habit.lastCompletedDate!.year == now.year &&
            habit.lastCompletedDate!.month == now.month &&
            habit.lastCompletedDate!.day == now.day;
            
        if (!isSameDay) {
          habit.isCompletedToday = false;
          // Note: Ici on pourrait ajouter une logique pour remettre le streak à 0 
          // si l'utilisateur a raté hier. Pour l'instant, on reste gentil.
          habit.save();
        }
      }
    }
    notifyListeners();
  }

  void addHabit(String title) {
    final newHabit = Habit(
      id: DateTime.now().toString(),
      title: title,
      streak: 0,
    );
    final box = Hive.box<Habit>(boxName);
    box.add(newHabit);
    loadHabits();
  }

  void toggleHabit(Habit habit) {
    habit.isCompletedToday = !habit.isCompletedToday;
    
    if (habit.isCompletedToday) {
      // ✅ Tâche validée
      habit.lastCompletedDate = DateTime.now();
      habit.streak++; // +1 Série
      updateScore(10); // +10 Pièces
    } else {
      // ❌ Tâche annulée (si on s'est trompé)
      habit.streak = (habit.streak > 0) ? habit.streak - 1 : 0;
      updateScore(-10); // On reprend l'argent
    }
    
    habit.save();
    notifyListeners();
  }

  void updateScore(int amount) {
    userScore += amount;
    // On empêche le score d'être négatif
    if (userScore < 0) userScore = 0;
    
    // Sauvegarde du score
    var box = Hive.box(settingsBoxName);
    box.put('score', userScore);
  }

  void deleteHabit(Habit habit) {
    habit.delete();
    loadHabits();
  }
}