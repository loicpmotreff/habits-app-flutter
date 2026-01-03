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
  bool isDarkMode = false;
  
  // --- BADGES ---
  List<String> unlockedBadgeIds = []; // Liste des IDs débloqués

  // LISTE DES BADGES POSSIBLES
  final List<AppBadge> allBadges = [
    AppBadge(id: 'first_step', title: 'Premier Pas', description: 'Valider une première habitude.', icon: Icons.directions_walk, color: Colors.green),
    AppBadge(id: 'streak_3', title: 'Bon départ', description: 'Série de 3 jours.', icon: Icons.local_fire_department, color: Colors.orange),
    AppBadge(id: 'streak_7', title: 'En feu !', description: 'Série de 7 jours.', icon: Icons.whatshot, color: Colors.deepOrange),
    AppBadge(id: 'streak_30', title: 'Légende', description: 'Série de 30 jours.', icon: Icons.emoji_events, color: Colors.amber),
    AppBadge(id: 'worker_10', title: 'Travailleur', description: '10 habitudes validées au total.', icon: Icons.fitness_center, color: Colors.blue),
    AppBadge(id: 'worker_50', title: 'Machine', description: '50 habitudes validées au total.', icon: Icons.precision_manufacturing, color: Colors.purple),
    AppBadge(id: 'level_5', title: 'Apprenti', description: 'Atteindre le niveau 5.', icon: Icons.school, color: Colors.teal),
    AppBadge(id: 'level_10', title: 'Expert', description: 'Atteindre le niveau 10.', icon: Icons.psychology, color: Colors.indigo),
    AppBadge(id: 'joker_use', title: 'Relax', description: 'Utiliser un joker pour la première fois.', icon: Icons.beach_access, color: Colors.cyan),
  ];

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
    isDarkMode = settingsBox.get('isDarkMode', defaultValue: false);
    
    // Charger les badges
    unlockedBadgeIds = (settingsBox.get('badges') != null) ? List<String>.from(settingsBox.get('badges')) : [];

    loadHabits();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    updateSettings();
    notifyListeners();
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

    // --- C'EST ICI QUE CA CHANGE POUR LE FLEXIBLE ---
    habits = allHabits.where((habit) {
        // Si c'est Flexible, on l'affiche TOUJOURS (ou selon ta logique préférée)
        if (habit.isFlexible) return true; 
        
        // Sinon (Jours fixes), on vérifie si on est le bon jour (Lundi, Mardi...)
        return habit.activeDays.contains(now.weekday);
    }).toList();
    
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
      // CHECK BADGE JOKER
      checkAchievements(); 
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
    
    // CHECK BADGE NIVEAU
    checkAchievements();
    updateSettings();
  }

  // --- SYSTÈME DE VÉRIFICATION DES BADGES ---
  void checkAchievements() {
    bool newUnlock = false;

    // 1. Calculer le total des validations (toutes habitudes confondues)
    int totalCompletions = 0;
    final box = Hive.box<Habit>(boxName); 
    for (var h in box.values) {
      totalCompletions += h.completedDays.length;
    }

    // 2. Vérifier chaque condition
    
    // Premier pas
    if (!unlockedBadgeIds.contains('first_step') && totalCompletions >= 1) {
      unlockedBadgeIds.add('first_step');
      newUnlock = true;
    }
    
    // Travailleurs (Volume)
    if (!unlockedBadgeIds.contains('worker_10') && totalCompletions >= 10) {
      unlockedBadgeIds.add('worker_10');
      newUnlock = true;
    }
    if (!unlockedBadgeIds.contains('worker_50') && totalCompletions >= 50) {
      unlockedBadgeIds.add('worker_50');
      newUnlock = true;
    }

    // Niveaux
    if (!unlockedBadgeIds.contains('level_5') && userLevel >= 5) {
      unlockedBadgeIds.add('level_5');
      newUnlock = true;
    }
    if (!unlockedBadgeIds.contains('level_10') && userLevel >= 10) {
      unlockedBadgeIds.add('level_10');
      newUnlock = true;
    }

    // Joker
    bool hasUsedJoker = box.values.any((h) => h.skippedDays.isNotEmpty);
    if (!unlockedBadgeIds.contains('joker_use') && hasUsedJoker) {
      unlockedBadgeIds.add('joker_use');
      newUnlock = true;
    }

    // Streaks (Séries)
    int bestStreak = 0;
    for (var h in box.values) {
      if (h.streak > bestStreak) bestStreak = h.streak;
    }

    if (!unlockedBadgeIds.contains('streak_3') && bestStreak >= 3) {
      unlockedBadgeIds.add('streak_3');
      newUnlock = true;
    }
    if (!unlockedBadgeIds.contains('streak_7') && bestStreak >= 7) {
      unlockedBadgeIds.add('streak_7');
      newUnlock = true;
    }
    if (!unlockedBadgeIds.contains('streak_30') && bestStreak >= 30) {
      unlockedBadgeIds.add('streak_30');
      newUnlock = true;
    }

    if (newUnlock) {
      updateSettings();
      notifyListeners();
      SoundManager.play('success.mp3'); 
    }
  }
  // ------------------------------------------

  // --- MODIFICATION ICI : Ajout de isFlexible et weeklyGoal ---
  void addHabit(
      String title, 
      List<int> days, 
      HabitDifficulty difficulty, 
      HabitCategory category, 
      int targetValue, 
      String unit, 
      bool isTimer, 
      bool isNegative, 
      bool isFlexible, 
      int weeklyGoal
    ) {
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
      isFlexible: isFlexible, // Nouveau champ
      weeklyGoal: weeklyGoal, // Nouveau champ
      isCompletedToday: startCompleted, 
      lastCompletedDate: DateTime.now(),
      skippedDays: [],
    );
    final box = Hive.box<Habit>(boxName);
    box.add(newHabit);
    loadHabits();
  }

  // --- MODIFICATION ICI : Ajout de isFlexible et weeklyGoal ---
  void updateHabit(
      String id, 
      String newTitle, 
      List<int> newDays, 
      HabitDifficulty newDifficulty, 
      HabitCategory newCategory, 
      int newTargetValue, 
      String newUnit, 
      bool isTimer, 
      bool isNegative, 
      bool isFlexible, 
      int weeklyGoal
    ) {
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
      habit.isFlexible = isFlexible; // Mise à jour
      habit.weeklyGoal = weeklyGoal; // Mise à jour
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

      int baseReward = 10; 
      updateScore(baseReward);
      addXP(baseReward);

      if (!habit.completedDays.contains(todayNormalized)) {
        habit.completedDays.add(todayNormalized);
      }
      
      // CHECK BADGES APRÈS VALIDATION
      checkAchievements(); 
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
    box.put('isDarkMode', isDarkMode);
    box.put('badges', unlockedBadgeIds);
  }

  void deleteHabit(Habit habit) {
    habit.delete();
    loadHabits();
  }

  // Calcule combien de fois une habitude a été faite cette semaine (Lundi -> Dimanche)
  int getWeeklyProgress(Habit habit) {
    final now = DateTime.now();
    // On trouve le Lundi de la semaine actuelle à 00:00:00
    // now.weekday : 1 = Lundi, 7 = Dimanche
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    int count = 0;
    for (var date in habit.completedDays) {
      // On compare si la date est après ou égale au début de la semaine
      if (date.isAfter(startOfWeek) || date.isAtSameMomentAs(startOfWeek)) {
        count++;
      }
    }
    return count;
  }
  
}

// --- CLASSE SIMPLE POUR LES BADGES ---
class AppBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  AppBadge({
    required this.id, 
    required this.title, 
    required this.description, 
    required this.icon, 
    required this.color
  });
}

