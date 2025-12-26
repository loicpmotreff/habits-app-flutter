import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/habit_database.dart';
import 'package:animate_do/animate_do.dart'; 
import 'package:confetti/confetti.dart';     
import 'dart:math';
import 'shop_page.dart'; // Pour qu'il connaisse la boutique

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // On instancie la BDD
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(), // <--- CHANGEMENT ICI
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Page actuelle (0 = Habitudes, 1 = Boutique)

  // La liste des pages
  final List<Widget> _pages = [
    const HabitPage(), // Ta page existante
    const ShopPage(),  // La nouvelle page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On affiche la page qui correspond à l'index actuel
      body: _pages[_currentIndex],
      
      // La barre de navigation en bas
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index; // Change la page
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: Colors.deepPurple),
            label: 'Habitudes',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: Colors.deepPurple),
            label: 'Boutique',
          ),
        ],
      ),
    );
  }
}

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
    // On initialise le canon à confettis (durée 1 seconde)
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _createNewHabit(BuildContext context) {
    final controller = TextEditingController();
    // Par défaut, tous les jours sont sélectionnés (Lundi à Dimanche)
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7]; 
    
    showDialog(
      context: context,
      builder: (context) {
        // On utilise StatefulBuilder pour que la boîte de dialogue puisse se mettre à jour
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Nouvelle quête 📜"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Ex: Sport",
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 15),
                  const Text("Fréquence :", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Les 7 petits boutons pour les jours
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white
                  ),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      // On envoie le titre ET les jours
                      context.read<HabitDatabase>().addHabit(controller.text, selectedDays);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Créer"),
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
      // On empile les widgets pour mettre les confettis PAR DESSUS tout le reste
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 1. Le contenu principal
          Scaffold(
            backgroundColor: Colors.transparent, // Important pour voir le fond
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Consumer<HabitDatabase>(
                builder: (context, db, child) {
                  return FadeInDown( // Animation du score qui tombe du haut
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
              onPressed: () => _createNewHabit(context),
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Nouvelle Quête", style: TextStyle(color: Colors.white)),
            ),
            body: Consumer<HabitDatabase>(
              builder: (context, db, child) {
                return Column(
                  children: [
                    // ANIMAL (Animé avec un petit rebond "ElasticIn")
                    ElasticIn(
                      duration: const Duration(seconds: 2),
                      child: PetWidget(score: db.userScore),
                    ),

                    // LISTE DES HABITUDES
                    Expanded(
                      child: db.habits.isEmpty
                          ? Center(
                              child: FadeInUp(
                                child: const Text("Tout est calme... Trop calme.", 
                                  style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : ListView.builder(
                              itemCount: db.habits.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                final habit = db.habits[index];
                                
                                // Chaque carte arrive une par une (Cascade)
                                return FadeInLeft(
                                  duration: const Duration(milliseconds: 500),
                                  delay: Duration(milliseconds: index * 100), // Effet domino
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
                                      title: Text(
                                        habit.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          decoration: habit.isCompletedToday ? TextDecoration.lineThrough : null,
                                          color: habit.isCompletedToday ? Colors.grey[400] : Colors.black87,
                                        ),
                                      ),
                                      leading: Transform.scale(
                                        scale: 1.2,
                                        child: Checkbox(
                                          value: habit.isCompletedToday,
                                          activeColor: Colors.green, // Vert succès
                                          shape: const CircleBorder(),
                                          onChanged: (val) {
                                            db.toggleHabit(habit);
                                            // Si on coche (val == true), on lance les confettis !
                                            if (val == true) {
                                              _confettiController.play();
                                            }
                                          },
                                        ),
                                      ),
                                      subtitle: habit.streak > 0
                                          ? Row(
                                              children: [
                                                const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                                                Text(" ${habit.streak} jours", style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                                              ],
                                            )
                                          : const Text("Commence ta série !", style: TextStyle(fontSize: 12, color: Colors.grey)),
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

          // 2. Le Canon à Confettis (Invisible tant qu'il ne tire pas)
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // Tire vers le bas (pluie)
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
// Ce widget gère l'affichage de l'animal selon le score
class PetWidget extends StatelessWidget {
  final int score;

  const PetWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    // Logique d'évolution
    String imagePath;
    String statusText;

    if (score < 50) {
      imagePath = 'assets/images/pet_egg.png';
      statusText = "Stade : Œuf (Encore ${50 - score} pièces pour éclore)";
    } else if (score < 100) {
      imagePath = 'assets/images/pet_baby.png';
      statusText = "Stade : Bébé (Encore ${100 - score} pièces pour grandir)";
    } else {
      imagePath = 'assets/images/pet_adult.png';
      statusText = "Stade : Maître des Habitudes !";
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
          // L'image de l'animal
          Image.asset(
            imagePath,
            height: 150, // Taille de l'image
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          // Le texte de statut
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
          // Barre de progression (Optionnelle mais satisfaisante)
          LinearProgressIndicator(
            value: (score % 50) / 50, // Progression vers le prochain niveau
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