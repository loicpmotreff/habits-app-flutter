import 'package:hive/hive.dart';

part 'habit.g.dart';

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
  List<int> activeDays; // 1 = Lundi, 7 = Dimanche

  @HiveField(6)
  List<DateTime> completedDays; // Historique pour le calendrier

  Habit({
    required this.id,
    required this.title,
    this.isCompletedToday = false,
    this.lastCompletedDate,
    this.streak = 0,
    required this.activeDays,
    this.completedDays = const [], // Initialisé vide par défaut
  });
}