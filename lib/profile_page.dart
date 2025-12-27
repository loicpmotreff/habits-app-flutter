import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'database/habit_database.dart';
import 'models/habit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mon Profil 📈"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<HabitDatabase>(
        builder: (context, db, child) {
          // PRÉPARATION DES DONNÉES POUR LE CALENDRIER
          // On veut savoir : pour chaque date, combien d'habitudes ont été faites ?
          Map<DateTime, int> dataset = {};

          for (var habit in db.habits) {
            for (var date in habit.completedDays) {
              // On normalise la date (juste pour être sûr)
              final normalizedDate = DateTime(date.year, date.month, date.day);
              
              if (dataset.containsKey(normalizedDate)) {
                dataset[normalizedDate] = dataset[normalizedDate]! + 1;
              } else {
                dataset[normalizedDate] = 1;
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. Avatar (Animal actuel)
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: db.itemActive != 'default' 
                      ? AssetImage("assets/images/${db.itemActive}_adult.png") // On montre la version adulte pour le style
                      : const AssetImage("assets/images/pet_adult.png"),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Maître des Habitudes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
              ),
              const SizedBox(height: 30),

              // 2. Le Calendrier Heatmap
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Activité du mois", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    HeatMap(
                      startDate: DateTime.now().subtract(const Duration(days: 60)), // Commence il y a 2 mois
                      endDate: DateTime.now().add(const Duration(days: 7)), // Finit dans 1 semaine
                      datasets: dataset,
                      colorMode: ColorMode.opacity,
                      showText: false,
                      scrollable: true,
                      colorsets: const {
                        1: Colors.deepPurple, // La couleur des cases actives
                      },
                      onClick: (value) {
                        // Action si on clique sur une date (optionnel)
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Tu as validé ${dataset[value] ?? 0} tâches ce jour-là !"))
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 3. Quelques Stats Rapides
              Row(
                children: [
                  _buildStatCard("Total Tâches", "${dataset.length}", Colors.blue),
                  const SizedBox(width: 15),
                  _buildStatCard("Argent", "${db.userScore}", Colors.amber),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 5),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}