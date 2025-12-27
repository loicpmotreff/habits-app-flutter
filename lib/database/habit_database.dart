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
    Hive.registerAdapter(HabitAdapter());

    // --- DÉBUT DE LA SÉCURITÉ ---
    try {
      // On essaie d'ouvrir la boîte normalement
      await Hive.openBox<Habit>(boxName);
    } catch (e) {
      // 🚨 AÏE ! Ça a planté (conflit de données)
      print("Erreur détectée : Anciennes données incompatibles. Nettoyage...");
      // On supprime la boîte corrompue
      await Hive.deleteBoxFromDisk(boxName);
      // On la rouvre toute propre
      await Hive.openBox<Habit>(boxName);
    }
    // --- FIN DE LA SÉCURITÉ ---

    var settingsBox = await Hive.openBox(settingsBoxName);
    
    // Chargement sécurisé (avec des protections '??' partout)
    userScore = (settingsBox.get('score') ?? 0) as int;
    
    // Protection spéciale pour l'inventaire qui posait problème aussi
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
    
    // 1. Reset du jour
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

  // AJOUTER UNE HABITUDE (Mise à jour avec completedDays)
  void addHabit(String title, List<int> days) {
    final newHabit = Habit(
      id: DateTime.now().toString(),
      title: title,
      streak: 0,
      activeDays: days,
      completedDays: [], // On commence avec une liste vide
    );
    final box = Hive.box<Habit>(boxName);
    box.add(newHabit);
    loadHabits();
  }

  // MODIFIER UNE HABITUDE
  void updateHabit(String id, String newTitle, List<int> newDays) {
    final habitIndex = habits.indexWhere((h) => h.id == id);
    if (habitIndex != -1) {
      final habit = habits[habitIndex];
      habit.title = newTitle;
      habit.activeDays = newDays;
      habit.save();
      loadHabits();
    }
  }

  // COCHER / DÉCOCHER (Avec gestion de l'historique pour le Heatmap)
  void toggleHabit(Habit habit) {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    habit.isCompletedToday = !habit.isCompletedToday;

    if (habit.isCompletedToday) {
      // ✅ Validé
      habit.lastCompletedDate = DateTime.now();
      habit.streak++;
      updateScore(10);
      
      // Ajout à l'historique
      if (!habit.completedDays.contains(todayNormalized)) {
        habit.completedDays.add(todayNormalized);
      }
    } else {
      // ❌ Annulé
      habit.streak = (habit.streak > 0) ? habit.streak - 1 : 0;
      updateScore(-10); 
      
      // Retrait de l'historique
      habit.completedDays.removeWhere((date) => 
        date.year == today.year && 
        date.month == today.month && 
        date.day == today.day
      );
    }
    
    habit.save();
    notifyListeners();
  }

  // GESTION DU SCORE ET INVENTAIRE
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