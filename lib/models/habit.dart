import 'package:hive/hive.dart';

part 'habit.g.dart';

// 1. On définit les niveaux de difficulté
@HiveType(typeId: 1) // Attention : typeId différent de Habit (qui est 0)
enum HabitDifficulty {
  @HiveField(0)
  easy,
  @HiveField(1)
  medium,
  @HiveField(2)
  hard,
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

  @HiveField(7) // NOUVEAU CHAMPS
  HabitDifficulty difficulty;

  Habit({
    required this.id,
    required this.title,
    this.isCompletedToday = false,
    this.lastCompletedDate,
    this.streak = 0,
    required this.activeDays,
    this.completedDays = const [],
    this.difficulty = HabitDifficulty.medium, // Par défaut "Moyen"
  });
}