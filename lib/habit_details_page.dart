import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../models/habit.dart'; 
import '../database/habit_database.dart'; 
import '../sound_manager.dart'; 

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
      dataset[normalizedDate] = 2; 
    }
    
    return dataset;
  }

  String _calculateSuccessRate() {
    if (widget.habit.completedDays.isEmpty) return "0";
    return "${widget.habit.completedDays.length}";
  }

  @override
  Widget build(BuildContext context) {
    // Détection du mode sombre
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    // Vérifier si Joker activé aujourd'hui
    bool isSkippedToday = widget.db.isHabitSkippedToday(widget.habit);

    // Calcul de la progression hebdo (pour les flexibles)
    int weeklyProgress = widget.db.getWeeklyProgress(widget.habit);

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: textColor),
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
                        color: isSkippedToday ? (isDark ? Colors.grey[800] : Colors.grey[300]) : habitColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isSkippedToday ? Icons.beach_access : (widget.habit.isNegative ? Icons.block : Icons.check_circle),
                        color: isSkippedToday ? Colors.grey : habitColor,
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
                        color: isSkippedToday ? Colors.grey : textColor
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
                  color: isSkippedToday 
                      ? (isDark ? Colors.grey[800] : Colors.grey[300]) 
                      : (isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: isSkippedToday 
                          ? Colors.grey 
                          : (isDark ? Colors.blue.shade700 : Colors.blue.shade200)
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isSkippedToday ? "Journée Joker 🏖️" : "Besoin de repos ?", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        Text(
                          isSkippedToday ? "Ta série est protégée." : "Utilise un joker pour protéger ta série.", 
                          style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))
                        ),
                      ],
                    ),
                    Switch(
                      value: isSkippedToday,
                      activeThumbColor: Colors.grey[400],
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
                  // Carte de gauche : Série OU Hebdo
                  widget.habit.isFlexible 
                  ? _buildStatCard(
                      "Cette semaine", 
                      "$weeklyProgress / ${widget.habit.weeklyGoal}", 
                      Icons.calendar_view_week_rounded, 
                      Colors.cyan, 
                      cardColor, 
                      textColor
                    )
                  : _buildStatCard(
                      "Série Actuelle", 
                      "${widget.habit.streak} j", 
                      Icons.local_fire_department, 
                      Colors.orange, 
                      cardColor, 
                      textColor
                    ),
                  
                  const SizedBox(width: 10),
                  
                  // Carte de droite : Total
                  _buildStatCard(
                    "Total Validé", 
                    _calculateSuccessRate(), 
                    Icons.emoji_events, 
                    Colors.amber, 
                    cardColor, 
                    textColor
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 4. CALENDRIER (HEATMAP)
              Text("Historique", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Center(
                  child: HeatMapCalendar(
                    datasets: _prepareHeatmapDataset(),
                    colorMode: ColorMode.color,
                    defaultColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    textColor: textColor,
                    showColorTip: false,
                    size: 28,
                    margin: const EdgeInsets.all(4),
                    colorsets: {
                      1: habitColor,
                      2: Colors.grey,
                    },
                    onClick: (value) {},
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 5. BOUTON SUPPRIMER (CORRIGÉ ICI 👇)
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
                              // 1. ON FERME D'ABORD LES PAGES
                              Navigator.pop(context); // Ferme l'alerte
                              Navigator.pop(context); // Ferme la page de détails
                              
                              // 2. ENSUITE ON SUPPRIME
                              widget.db.deleteHabit(widget.habit);
                              //SoundManager.play('error.mp3');
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

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor, Color txtColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: txtColor)),
            Text(title, style: TextStyle(color: txtColor.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}