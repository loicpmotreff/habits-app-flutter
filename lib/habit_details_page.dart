import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'models/habit.dart';
import 'database/habit_database.dart';
import 'sound_manager.dart';

class HabitDetailsPage extends StatelessWidget {
  final Habit habit;
  final HabitDatabase db;
  final VoidCallback onEdit;

  const HabitDetailsPage({
    super.key,
    required this.habit,
    required this.db,
    required this.onEdit,
  });

  Map<DateTime, int> _prepareHeatmapDataset() {
    Map<DateTime, int> dataset = {};
    for (var date in habit.completedDays) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      dataset[normalizedDate] = 1;
    }
    return dataset;
  }

  String _calculateSuccessRate() {
    if (habit.completedDays.isEmpty) return "0";
    return "${habit.completedDays.length}";
  }

  @override
  Widget build(BuildContext context) {
    Color habitColor;
    switch (habit.category) {
      case HabitCategory.sport: habitColor = Colors.orange; break;
      case HabitCategory.work: habitColor = Colors.blue; break;
      case HabitCategory.health: habitColor = Colors.pink; break;
      case HabitCategory.art: habitColor = Colors.purple; break;
      case HabitCategory.social: habitColor = Colors.teal; break;
      default: habitColor = Colors.grey; break;
    }
    if (habit.isNegative) habitColor = Colors.red;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TITRE & ICONE
              Row(
                children: [
                  Hero(
                    tag: "habit_icon_${habit.id}",
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: habitColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        habit.isNegative ? Icons.block : Icons.check_circle,
                        color: habitColor,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      habit.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // 2. LES STATS
              Row(
                children: [
                  _buildStatCard("Série Actuelle", "${habit.streak} j", Icons.local_fire_department, Colors.orange),
                  const SizedBox(width: 10),
                  _buildStatCard("Total Validé", _calculateSuccessRate(), Icons.emoji_events, Colors.amber),
                ],
              ),

              const SizedBox(height: 30),

              // 3. CALENDRIER (HEATMAP)
              const Text("Historique", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                width: double.infinity, // Prend toute la largeur
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Center( // <--- LE SECRET DU CENTRAGE EST ICI
                  child: HeatMapCalendar(
                    datasets: _prepareHeatmapDataset(),
                    colorMode: ColorMode.color,
                    defaultColor: Colors.grey[200],
                    textColor: Colors.black,
                    showColorTip: false,
                    size: 28, // Taille ajustée pour bien rentrer
                    margin: const EdgeInsets.all(4),
                    colorsets: {
                      1: habitColor,
                    },
                    onClick: (value) {},
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 4. BOUTON SUPPRIMER
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Supprimer ?"),
                        content: const Text("Cette action est irréversible."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                          TextButton(
                            onPressed: () {
                              db.deleteHabit(habit);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              SoundManager.play('error.mp3');
                            },
                            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                  label: Text("Supprimer cette habitude", style: TextStyle(color: Colors.red[300])),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}