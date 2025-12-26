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
    final allHabits = box.values.toList();
    final now = DateTime.now();
    
    // 1. Reset du jour (inchangé)
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
    // now.weekday donne 1 pour Lundi, ..., 7 pour Dimanche
    habits = allHabits.where((habit) {
      return habit.activeDays.contains(now.weekday);
    }).toList();

    notifyListeners();
  }

  // On ajoute les jours choisis en paramètre
  void addHabit(String title, List<int> days) {
    final newHabit = Habit(
      id: DateTime.now().toString(),
      title: title,
      streak: 0,
      activeDays: days, // On stocke les jours
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