import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/habit_database.dart';
import 'settings_page.dart'; // N'oublie pas l'import !

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<HabitDatabase>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calcul Stats Badges
    int unlockedCount = db.unlockedBadgeIds.length;
    int totalCount = db.allBadges.length;
    double progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // ON AJOUTE L'ICÔNE ICI VIA UNE APPBAR TRANSPARENTE
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: Icon(Icons.settings, color: theme.colorScheme.primary, size: 28),
              onPressed: () {
                // Navigation vers la page Paramètres (Push classique)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.person, size: 50, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 10),
            Text("Mon Profil", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)),
            Text("Chasseur de badges", style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            
            const SizedBox(height: 30),

            // BARRE DE PROGRESSION BADGES
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Succès débloqués", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("$unlockedCount / $totalCount", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // GRILLE DES BADGES
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: db.allBadges.length,
              itemBuilder: (context, index) {
                final badge = db.allBadges[index];
                bool isUnlocked = db.unlockedBadgeIds.contains(badge.id);

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? (isDark ? Colors.grey[800] : Colors.white) 
                        : (isDark ? Colors.grey[900] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(15),
                    border: isUnlocked ? Border.all(color: badge.color.withOpacity(0.3), width: 2) : null,
                    boxShadow: isUnlocked ? [BoxShadow(color: badge.color.withOpacity(0.1), blurRadius: 8)] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked ? badge.color.withOpacity(0.1) : Colors.transparent,
                        ),
                        child: Icon(
                          isUnlocked ? badge.icon : Icons.lock,
                          color: isUnlocked ? badge.color : Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        badge.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? (theme.textTheme.bodyMedium?.color) : Colors.grey
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}