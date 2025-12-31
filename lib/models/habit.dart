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
  List<int> activeDays;

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

  // --- NOUVEAU CHAMP ---
  @HiveField(13, defaultValue: false)
  bool isNegative; // True = "À ne pas faire" (Commence validé)

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
    this.isNegative = false, // Par défaut c'est une habitude positive
  });
}