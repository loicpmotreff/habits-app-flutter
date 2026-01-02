import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/habit_database.dart';
import 'sound_manager.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<HabitDatabase>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Paramètres", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION : APPARENCE
              _buildSectionTitle(context, "Apparence"),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: theme.colorScheme.primary),
                      title: const Text("Mode Sombre"),
                      value: db.isDarkMode,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) => db.toggleTheme(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // SECTION : DONNÉES
              _buildSectionTitle(context, "Données & Zone de danger"),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text("Tout effacer", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Réinitialiser quêtes, niveaux et badges."),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Attention !"),
                        content: const Text("Tu vas perdre toute ta progression (Niveaux, Badges, Habitudes). Es-tu sûr ?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fonctionnalité à venir (sécurité)")));
                              SoundManager.play('error.mp3');
                            },
                            child: const Text("Tout effacer", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 40),
              Center(
                child: Text("Version 2.1.0\nFait avec ❤️ avec Flutter", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2),
      ),
    );
  }
}