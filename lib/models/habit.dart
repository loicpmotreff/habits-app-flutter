import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 1)
enum HabitDifficulty {
  @HiveField(0) easy,
  @HiveField(1) medium,
  @HiveField(2) hard,
}

@HiveType(typeId: 2)
enum HabitCategory {
  @HiveField(0) sport,
  @HiveField(1) work,
  @HiveField(2) health,
  @HiveField(3) art,
  @HiveField(4) social,
  @HiveField(5) other,
}

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompletedToday;

  @HiveField(3)
  DateTime? lastCompletedDate;

  @HiveField(4)
  int streak;

  @HiveField(5)
  List<int> activeDays; // Utilisé si isFlexible == false

  @HiveField(6)
  List<DateTime> completedDays;

  @HiveField(7, defaultValue: HabitDifficulty.medium)
  HabitDifficulty difficulty;

  @HiveField(8, defaultValue: HabitCategory.other)
  HabitCategory category;

  @HiveField(9, defaultValue: 1)
  int targetValue;

  @HiveField(10, defaultValue: 0)
  int currentValue;

  @HiveField(11, defaultValue: '') 
  String unit;

  @HiveField(12, defaultValue: false)
  bool isTimer;

  @HiveField(13, defaultValue: false)
  bool isNegative;

  @HiveField(14, defaultValue: [])
  List<DateTime> skippedDays; 

  // --- NOUVEAUX CHAMPS POUR LE MODE FLEXIBLE ---

  @HiveField(15, defaultValue: false)
  bool isFlexible; // Si True = on vise un nombre de fois/semaine. Si False = jours précis.

  @HiveField(16, defaultValue: 1)
  int weeklyGoal; // Ex: 3 fois par semaine

  Habit({
    required this.id,
    required this.title,
    this.isCompletedToday = false,
    this.lastCompletedDate,
    this.streak = 0,
    required this.activeDays,
    this.completedDays = const [],
    this.difficulty = HabitDifficulty.medium,
    this.category = HabitCategory.other,
    this.targetValue = 1,
    this.currentValue = 0,
    this.unit = '',
    this.isTimer = false,
    this.isNegative = false,
    this.skippedDays = const [],
    this.isFlexible = false, // Valeur par défaut
    this.weeklyGoal = 1,     // Valeur par défaut
  });
}