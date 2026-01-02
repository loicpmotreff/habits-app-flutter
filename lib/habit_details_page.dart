import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'models/habit.dart';
import 'database/habit_database.dart';
import 'sound_manager.dart';

class HabitDetailsPage extends StatefulWidget {
  final Habit habit;
  final HabitDatabase db;
  final VoidCallback onEdit;

  const HabitDetailsPage({
    super.key,
    required this.habit,
    required this.db,
    required this.onEdit,
  });

  @override
  State<HabitDetailsPage> createState() => _HabitDetailsPageState();
}

class _HabitDetailsPageState extends State<HabitDetailsPage> {
  
  // Prépare les données pour le calendrier (Vert = Fait, Gris = Joker)
  Map<DateTime, int> _prepareHeatmapDataset() {
    Map<DateTime, int> dataset = {};
    
    // 1. Les jours validés (Couleur normale = 1)
    for (var date in widget.habit.completedDays) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      dataset[normalizedDate] = 1;
    }

    // 2. Les jours Joker (Gris = 2)
    for (var date in widget.habit.skippedDays) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      dataset[normalizedDate] = 2; // Intensité différente pour couleur différente
    }
    
    return dataset;
  }

  String _calculateSuccessRate() {
    if (widget.habit.completedDays.isEmpty) return "0";
    return "${widget.habit.completedDays.length}";
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si Joker activé aujourd'hui
    bool isSkippedToday = widget.db.isHabitSkippedToday(widget.habit);

    Color habitColor;
    switch (widget.habit.category) {
      case HabitCategory.sport: habitColor = Colors.orange; break;
      case HabitCategory.work: habitColor = Colors.blue; break;
      case HabitCategory.health: habitColor = Colors.pink; break;
      case HabitCategory.art: habitColor = Colors.purple; break;
      case HabitCategory.social: habitColor = Colors.teal; break;
      default: habitColor = Colors.grey; break;
    }
    if (widget.habit.isNegative) habitColor = Colors.red;

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
              widget.onEdit();
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
                    tag: "habit_icon_${widget.habit.id}",
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSkippedToday ? Colors.grey : habitColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isSkippedToday ? Icons.beach_access : (widget.habit.isNegative ? Icons.block : Icons.check_circle),
                        color: isSkippedToday ? Colors.grey[700] : habitColor,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      widget.habit.title,
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        decoration: isSkippedToday ? TextDecoration.lineThrough : null,
                        color: isSkippedToday ? Colors.grey : Colors.black
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),

              // 2. LE BOUTON JOKER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: isSkippedToday ? Colors.grey[300] : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isSkippedToday ? Colors.grey : Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isSkippedToday ? "Journée Joker 🏖️" : "Besoin de repos ?", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(isSkippedToday ? "Ta série est protégée." : "Utilise un joker pour protéger ta série.", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Switch(
                      value: isSkippedToday,
                      activeColor: Colors.grey[700],
                      onChanged: (val) {
                        setState(() {
                           widget.db.toggleSkipHabit(widget.habit);
                        });
                      },
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 3. LES STATS
              Row(
                children: [
                  _buildStatCard("Série Actuelle", "${widget.habit.streak} j", Icons.local_fire_department, Colors.orange),
                  const SizedBox(width: 10),
                  _buildStatCard("Total Validé", _calculateSuccessRate(), Icons.emoji_events, Colors.amber),
                ],
              ),

              const SizedBox(height: 30),

              // 4. CALENDRIER (HEATMAP)
              const Text("Historique", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Center(
                  child: HeatMapCalendar(
                    datasets: _prepareHeatmapDataset(),
                    colorMode: ColorMode.color,
                    defaultColor: Colors.grey[200],
                    textColor: Colors.black,
                    showColorTip: false,
                    size: 28,
                    margin: const EdgeInsets.all(4),
                    colorsets: {
                      1: habitColor,        // Couleur Validé
                      2: Colors.grey,       // Couleur Joker
                    },
                    onClick: (value) {},
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 5. BOUTON SUPPRIMER
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
                              widget.db.deleteHabit(widget.habit);
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