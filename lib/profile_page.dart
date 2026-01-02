import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/habit_database.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<HabitDatabase>();

    return Scaffold(
      backgroundColor: Colors.transparent, // Prend la couleur du thème principal
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade200,
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text("Mon Profil", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("Chasseur d'habitudes", style: TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 40),

              // Section Paramètres
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // S'adapte au mode sombre/clair
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text("Mode Sombre"),
                      trailing: Switch(
                        value: db.isDarkMode,
                        activeColor: Colors.blue,
                        onChanged: (val) {
                          db.toggleTheme();
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text("Réinitialiser les données"),
                      onTap: () {
                         // Ajoute une boîte de dialogue de confirmation ici si tu veux
                      },
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              const Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}