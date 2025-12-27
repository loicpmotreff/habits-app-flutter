import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart'; // Pour les animations d'entrée
import 'package:confetti/confetti.dart';     // Pour la fête !
import 'dart:math';                          // Pour pi

// Nos fichiers à nous
import 'database/habit_database.dart';
import 'models/habit.dart';
import 'shop_page.dart';      // Page Boutique
import 'inventory_page.dart'; // Page Inventaire

import 'profile_page.dart';
import 'sound_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialisation de la Base de Données
  final habitDb = HabitDatabase();
  await habitDb.init();

  runApp(
    ChangeNotifierProvider(
      create: (context) => habitDb,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Pet RPG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Round', // Si tu as une police custom, sinon retire cette ligne
      ),
      home: const MainScreen(), // On démarre sur l'écran principal avec la navigation
    );
  }
}

// ---------------------------------------------------------------------------
// ECRAN PRINCIPAL (Contient la barre de navigation en bas)
// ---------------------------------------------------------------------------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // La liste de nos 3 pages
  final List<Widget> _pages = [
  const HabitPage(),
  const InventoryPage(),
  const ShopPage(),
  const ProfilePage(), // NOUVEAU
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: Colors.deepPurple),
            label: 'Quêtes',
          ),
          NavigationDestination(
            icon: Icon(Icons.backpack_outlined),
            selectedIcon: Icon(Icons.backpack, color: Colors.deepPurple),
            label: 'Sac',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: Colors.deepPurple),
            label: 'Boutique',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.deepPurple),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE DES HABITUDES (La page principale du jeu)
// ---------------------------------------------------------------------------
class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Fonction unifiée pour CRÉER ou MODIFIER une habitude
  void _showHabitDialog(BuildContext context, {Habit? habitToEdit}) {
    final controller = TextEditingController(text: habitToEdit?.title ?? "");
    
    // Si on édite, on reprend les jours existants, sinon on coche tout par défaut
    List<int> selectedDays = habitToEdit != null 
        ? List<int>.from(habitToEdit.activeDays) 
        : [1, 2, 3, 4, 5, 6, 7]; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(habitToEdit == null ? "Nouvelle quête 📜" : "Modifier la quête ✏️"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Ex: Sport, Lecture...",
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 15),
                  const Text("Fréquence :", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Sélecteur de jours (L M M J V S D)
                  Wrap(
                    spacing: 5,
                    children: List.generate(7, (index) {
                      int dayId = index + 1; // 1 = Lundi
                      List<String> daysLabels = ["L", "M", "M", "J", "V", "S", "D"];
                      bool isSelected = selectedDays.contains(dayId);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              if (selectedDays.length > 1) selectedDays.remove(dayId);
                            } else {
                              selectedDays.add(dayId);
                            }
                          });
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[200],
                          child: Text(
                            daysLabels[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      if (habitToEdit == null) {
                        // CRÉATION
                        context.read<HabitDatabase>().addHabit(controller.text, selectedDays);
                      } else {
                        // MODIFICATION
                        context.read<HabitDatabase>().updateHabit(habitToEdit.id, controller.text, selectedDays);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(habitToEdit == null ? "Créer" : "Sauvegarder"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // STACK pour les confettis par dessus tout
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Consumer<HabitDatabase>(
                builder: (context, db, child) {
                  return FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            "${db.userScore} Pièces",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              centerTitle: true,
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showHabitDialog(context),
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Nouvelle Quête", style: TextStyle(color: Colors.white)),
            ),
            body: Consumer<HabitDatabase>(
              builder: (context, db, child) {
                return Column(
                  children: [
                    // --- L'ANIMAL ---
                    ElasticIn(
                      duration: const Duration(seconds: 2),
                      child: PetWidget(
                        score: db.userScore,
                        activeSkin: db.itemActive,
                      ),
                    ),

                    // --- LA LISTE ---
                    Expanded(
                      child: db.habits.isEmpty
                          ? Center(
                              child: FadeInUp(
                                child: const Text(
                                  "Aucune quête aujourd'hui...\nProfite ou ajoute-en une !",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: db.habits.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              itemBuilder: (context, index) {
                                final habit = db.habits[index];
                                
                                return FadeInLeft(
                                  duration: const Duration(milliseconds: 500),
                                  delay: Duration(milliseconds: index * 100),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 5,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      // Clic sur le texte pour MODIFIER
                                      title: GestureDetector(
                                        onTap: () => _showHabitDialog(context, habitToEdit: habit),
                                        child: Text(
                                          habit.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            decoration: habit.isCompletedToday ? TextDecoration.lineThrough : null,
                                            color: habit.isCompletedToday ? Colors.grey[400] : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      // Checkbox pour VALIDER
                                      leading: Transform.scale(
                                        scale: 1.2,
                                        child: Checkbox(
                                          value: habit.isCompletedToday,
                                          activeColor: Colors.green,
                                          shape: const CircleBorder(),
                                          onChanged: (val) {
                                            db.toggleHabit(habit);
                                            if (val == true) {
                                              _confettiController.play();
                                              SoundManager.play('success.mp3');
                                            }
                                          },
                                        ),
                                      ),
                                      // Flamme de STREAK
                                      subtitle: habit.streak > 0
                                          ? Row(
                                              children: [
                                                const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                                                Text(" ${habit.streak} jours", style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                                              ],
                                            )
                                          : const Text("Commence ta série !", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      // Bouton SUPPRIMER
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.grey[300]),
                                        onPressed: () => db.deleteHabit(habit),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),

          // --- LES CONFETTIS ---
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET DE L'ANIMAL (Gère l'évolution et les skins)
// ---------------------------------------------------------------------------
class PetWidget extends StatelessWidget {
  final int score;
  final String activeSkin;

  const PetWidget({super.key, required this.score, required this.activeSkin});

  @override
  Widget build(BuildContext context) {
    String imagePrefix = "pet"; // Skin par défaut
    
    // Si un skin est actif et n'est pas "default", on change le préfixe
    if (activeSkin != 'default') {
      imagePrefix = activeSkin; 
    }

    String imagePath;
    String statusText;

    // Logique d'évolution (Œuf -> Bébé -> Adulte)
    if (score < 50) {
      imagePath = 'assets/images/${imagePrefix}_egg.png';
      statusText = "Stade : Œuf (Encore ${50 - score} pièces)";
    } else if (score < 100) {
      imagePath = 'assets/images/${imagePrefix}_baby.png';
      statusText = "Stade : Bébé (Encore ${100 - score} pièces)";
    } else {
      imagePath = 'assets/images/${imagePrefix}_adult.png';
      statusText = "Stade : Adulte (Niveau Max !)";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // On utilise Image.asset avec un gestionnaire d'erreur
          // Au cas où l'image du skin n'existe pas encore
          Image.asset(
            imagePath,
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.pets, size: 100, color: Colors.grey);
            },
          ),
          const SizedBox(height: 10),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Barre de progression
          LinearProgressIndicator(
            value: (score >= 100) ? 1.0 : (score % 50) / 50,
            backgroundColor: Colors.grey[200],
            color: Colors.orange,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}