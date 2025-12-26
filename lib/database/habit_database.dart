import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

class HabitDatabase extends ChangeNotifier {
  static const String boxName = 'habit_box';
  static const String settingsBoxName = 'settings_box'; // Pour stocker l'argent

  List<Habit> habits = [];
  int userScore = 0; // 🪙 Ton argent / XP

  List<String> inventory = []; // Liste des IDs des objets achetés (ex: ['skin_dragon'])
  String itemActive = 'default'; // Le skin actuel (par défaut 'default')

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(HabitAdapter());
    
    await Hive.openBox<Habit>(boxName);
    var settingsBox = await Hive.openBox(settingsBoxName);
    userScore = (settingsBox.get('score') ?? 0) as int;
    // Chargement de l'inventaire
    inventory = List<String>.from(settingsBox.get('inventory', defaultValue: []));
    itemActive = settingsBox.get('itemActive', defaultValue: 'default');

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

  // NOUVEAU : Fonction pour acheter un objet
  // Renvoie 'true' si l'achat a réussi, 'false' sinon (pas assez d'argent)
  bool buyItem(String itemId, int price) {
    if (inventory.contains(itemId)) {
      return true; // Déjà acheté
    }

    if (userScore >= price) {
      userScore -= price;
      inventory.add(itemId); // Ajout à l'inventaire
      updateSettings();      // Sauvegarde
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

  // Helper pour sauvegarder score + inventaire
  void updateSettings() {
    var box = Hive.box(settingsBoxName);
    box.put('score', userScore);
    box.put('inventory', inventory);
    box.put('itemActive', itemActive);
  }

  // NOUVEAU : Fonction pour modifier une habitude existante
  void updateHabit(String id, String newTitle, List<int> newDays) {
    // On cherche l'habitude dans la liste par son ID
    final habitIndex = habits.indexWhere((h) => h.id == id);
    
    if (habitIndex != -1) {
      final habit = habits[habitIndex];
      habit.title = newTitle;
      habit.activeDays = newDays;
      habit.save(); // Sauvegarde dans Hive
      loadHabits(); // Rafraîchit l'affichage (important si on change les jours)
    }
  }
}