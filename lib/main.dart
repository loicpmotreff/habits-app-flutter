import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:confetti/confetti.dart';
import 'dart:async'; // Pour le Timer
import 'dart:math';

import 'database/habit_database.dart';
import 'models/habit.dart';
import 'shop_page.dart';
import 'inventory_page.dart';
import 'profile_page.dart';
import 'sound_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HabitPage(),
    const InventoryPage(),
    const ShopPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Quêtes'),
          NavigationDestination(icon: Icon(Icons.backpack_outlined), selectedIcon: Icon(Icons.backpack), label: 'Sac'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Boutique'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
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
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getCategoryDetails(HabitCategory category) {
    switch (category) {
      case HabitCategory.sport: return {'icon': Icons.fitness_center, 'color': Colors.orange, 'label': 'Sport'};
      case HabitCategory.work: return {'icon': Icons.work, 'color': Colors.blue, 'label': 'Travail'};
      case HabitCategory.health: return {'icon': Icons.favorite, 'color': Colors.pink, 'label': 'Santé'};
      case HabitCategory.art: return {'icon': Icons.palette, 'color': Colors.purple, 'label': 'Art'};
      case HabitCategory.social: return {'icon': Icons.people, 'color': Colors.teal, 'label': 'Social'};
      default: return {'icon': Icons.circle, 'color': Colors.grey, 'label': 'Autre'};
    }
  }

  void _showHabitDialog(BuildContext context, {Habit? habitToEdit}) {
    final controller = TextEditingController(text: habitToEdit?.title ?? "");
    List<int> selectedDays = habitToEdit != null ? List<int>.from(habitToEdit.activeDays) : [1, 2, 3, 4, 5, 6, 7];
    HabitDifficulty selectedDifficulty = habitToEdit?.difficulty ?? HabitDifficulty.medium;
    HabitCategory selectedCategory = habitToEdit?.category ?? HabitCategory.other;
    TextEditingController targetController = TextEditingController(text: (habitToEdit?.targetValue ?? 1).toString());
    TextEditingController unitController = TextEditingController(text: habitToEdit?.unit ?? "");
    
    // NOUVEAU : Interrupteur Timer
    bool isTimerMode = habitToEdit?.isTimer ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(habitToEdit == null ? "Nouvelle quête" : "Modifier"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: controller, decoration: const InputDecoration(hintText: "Titre", border: OutlineInputBorder()), autofocus: true),
                    const SizedBox(height: 15),

                    // SWITCH TIMER
                    // ... (Le début de la colonne avec le TextField titre reste pareil)

                    const SizedBox(height: 10), // Un peu d'espace avant le bloc chrono

                    // BLOC CHRONOMÈTRE
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.05), // Fond très léger
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text("Mode Chronomètre ⏱️", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text("Lancer un compte à rebours", style: TextStyle(fontSize: 12)),
                            value: isTimerMode,
                            activeColor: Colors.deepPurple,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10), // Réduit les marges internes
                            onChanged: (val) {
                              setState(() {
                                isTimerMode = val;
                                if (isTimerMode && unitController.text.isEmpty) {
                                  unitController.text = "min";
                                }
                              });
                            },
                          ),
                          
                          // LA SÉPARATION QUE TU VOULAIS
                          if (isTimerMode) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Divider(height: 1), // Ligne fine
                            ),
                            const SizedBox(height: 15), // Espace aéré
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 15), // Espace entre le bloc chrono et les champs

                    // LES CHAMPS DE SAISIE (Objectif / Unité)
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: targetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isTimerMode ? "Durée" : "Objectif",
                              helperText: isTimerMode ? "en minutes" : "ex: 5", // Aide visuelle en dessous
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: unitController,
                            enabled: !isTimerMode,
                            decoration: InputDecoration(
                              labelText: "Unité",
                              helperText: isTimerMode ? "Auto" : "ex: verres", // Aide visuelle
                              hintText: isTimerMode ? "minutes" : "fois",
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20), // Espace avant les boutons de difficulté

                    // ... (La suite avec DropdownButton reste pareil)
                    
                    // Sélecteurs (Difficulty, Category, Days) - Version compacte pour gagner de la place
                    DropdownButton<HabitDifficulty>(
                      value: selectedDifficulty,
                      isExpanded: true,
                      onChanged: (val) => setState(() => selectedDifficulty = val!),
                      items: const [
                        DropdownMenuItem(value: HabitDifficulty.easy, child: Text("Facile (+5)")),
                        DropdownMenuItem(value: HabitDifficulty.medium, child: Text("Moyen (+10)")),
                        DropdownMenuItem(value: HabitDifficulty.hard, child: Text("Difficile (+20)")),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: HabitCategory.values.map((cat) {
                          final details = _getCategoryDetails(cat);
                          return Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: ChoiceChip(
                              label: Text(details['label'], style: const TextStyle(fontSize: 11)),
                              avatar: Icon(details['icon'], size: 14, color: selectedCategory == cat ? Colors.white : details['color']),
                              selected: selectedCategory == cat,
                              selectedColor: details['color'],
                              onSelected: (selected) { if (selected) setState(() => selectedCategory = cat); },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 5,
                      children: List.generate(7, (index) {
                        int dayId = index + 1;
                        List<String> dl = ["L", "M", "M", "J", "V", "S", "D"];
                        bool isSel = selectedDays.contains(dayId);
                        return GestureDetector(
                          onTap: () => setState(() => isSel ? (selectedDays.length > 1 ? selectedDays.remove(dayId) : null) : selectedDays.add(dayId)),
                          child: CircleAvatar(radius: 14, backgroundColor: isSel ? Colors.deepPurple : Colors.grey[200], child: Text(dl[index], style: TextStyle(color: isSel ? Colors.white : Colors.black, fontSize: 10))),
                        );
                      }),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      int target = int.tryParse(targetController.text) ?? 1;
                      if (target < 1) target = 1;
                      String unit = isTimerMode ? "min" : unitController.text.trim();

                      if (habitToEdit == null) {
                        context.read<HabitDatabase>().addHabit(controller.text, selectedDays, selectedDifficulty, selectedCategory, target, unit, isTimerMode);
                      } else {
                        context.read<HabitDatabase>().updateHabit(habitToEdit.id, controller.text, selectedDays, selectedDifficulty, selectedCategory, target, unit, isTimerMode);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Sauvegarder"),
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
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Consumer<HabitDatabase>(
                builder: (context, db, child) => FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 28),
                        const SizedBox(width: 10),
                        Text("${db.userScore}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              centerTitle: true,
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showHabitDialog(context),
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Quête", style: TextStyle(color: Colors.white)),
            ),
            body: Consumer<HabitDatabase>(
              builder: (context, db, child) {
                return Column(
                  children: [
                    ElasticIn(child: PetWidget(score: db.userScore, activeSkin: db.itemActive)),
                    Expanded(
                      child: db.habits.isEmpty
                          ? Center(child: FadeInUp(child: const Text("Aucune quête aujourd'hui...", style: TextStyle(color: Colors.grey))))
                          : ListView.builder(
                              itemCount: db.habits.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              itemBuilder: (context, index) {
                                final habit = db.habits[index];
                                return FadeInLeft(
                                  duration: const Duration(milliseconds: 500),
                                  delay: Duration(milliseconds: index * 100),
                                  // ICI : ON UTILISE NOTRE NOUVEAU WIDGET "HabitTile"
                                  child: HabitTile(
                                    habit: habit, 
                                    db: db, 
                                    onEdit: () => _showHabitDialog(context, habitToEdit: habit),
                                    confettiController: _confettiController,
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
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            numberOfParticles: 20,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOUVEAU WIDGET : GÈRE L'AFFICHAGE ET LE TIMER DE CHAQUE HABITUDE
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// WIDGET HABIT TILE (Version Simplifiée qui ouvre le Focus Mode)
// ---------------------------------------------------------------------------
class HabitTile extends StatelessWidget {
  final Habit habit;
  final HabitDatabase db;
  final VoidCallback onEdit;
  final ConfettiController confettiController; // On le garde pour les checkboxes simples

  const HabitTile({super.key, required this.habit, required this.db, required this.onEdit, required this.confettiController});

  @override
  Widget build(BuildContext context) {
    // Détails visuels (Couleurs/Icones)
    Map<String, dynamic> details;
    switch (habit.category) {
      case HabitCategory.sport: details = {'icon': Icons.fitness_center, 'color': Colors.orange}; break;
      case HabitCategory.work: details = {'icon': Icons.work, 'color': Colors.blue}; break;
      case HabitCategory.health: details = {'icon': Icons.favorite, 'color': Colors.pink}; break;
      case HabitCategory.art: details = {'icon': Icons.palette, 'color': Colors.purple}; break;
      case HabitCategory.social: details = {'icon': Icons.people, 'color': Colors.teal}; break;
      default: details = {'icon': Icons.circle, 'color': Colors.grey}; break;
    }

    bool isCounter = habit.targetValue > 1 && !habit.isTimer;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: details['color'], width: 6)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        
        // --- GAUCHE : CHECKBOX OU PLAY ---
        leading: habit.isTimer
            ? IconButton(
                icon: Icon(
                  habit.isCompletedToday ? Icons.check_circle : Icons.play_circle_fill,
                  color: habit.isCompletedToday ? Colors.green : details['color'],
                  size: 34,
                ),
                onPressed: () {
                  if (!habit.isCompletedToday) {
                    // C'EST ICI QU'ON OUVRE LA NOUVELLE PAGE FOCUS
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FocusTimerPage(habit: habit, db: db),
                      ),
                    );
                  }
                },
              )
            : (!isCounter
                ? Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: habit.isCompletedToday,
                      activeColor: details['color'],
                      shape: const CircleBorder(),
                      onChanged: (val) {
                        int change = val == true ? 1 : -1;
                        db.updateProgress(habit, change);
                        if (val == true) {
                          confettiController.play();
                          SoundManager.play('success.mp3');
                        }
                      },
                    ),
                  )
                : null),

        // --- CENTRE : TITRE ---
        title: GestureDetector(
          onTap: onEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: habit.isCompletedToday ? TextDecoration.lineThrough : null,
                  color: habit.isCompletedToday ? Colors.grey[400] : Colors.black87,
                ),
              ),
              // Sous-titre conditionnel
              if (habit.isTimer)
                Text(
                   habit.isCompletedToday ? "Terminé !" : "${habit.targetValue} min",
                   style: TextStyle(color: Colors.grey[600], fontSize: 12),
                )
              else if (habit.streak > 0)
                 Row(children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                    Text(" ${habit.streak} j", style: TextStyle(color: Colors.orange[700], fontSize: 12)),
                 ]),
            ],
          ),
        ),

        // --- DROITE : COMPTEUR OU SUPPRESSION ---
        // On a enlevé le chrono d'ici pour éviter l'erreur OVERFLOW
        trailing: isCounter
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => db.updateProgress(habit, -1),
                  ),
                  Text("${habit.currentValue}/${habit.targetValue} ${habit.unit}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: details['color']),
                    onPressed: () {
                      db.updateProgress(habit, 1);
                      if (habit.currentValue + 1 >= habit.targetValue && !habit.isCompletedToday) {
                         confettiController.play();
                         SoundManager.play('success.mp3');
                      }
                    },
                  ),
                ],
              )
            : IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey[300]),
                onPressed: () => db.deleteHabit(habit),
              ),
      ),
    );
  }
}
class PetWidget extends StatelessWidget {
  final int score;
  final String activeSkin;
  const PetWidget({super.key, required this.score, required this.activeSkin});

  @override
  Widget build(BuildContext context) {
    String imagePrefix = activeSkin != 'default' ? activeSkin : "pet";
    String imagePath = score < 50 ? 'assets/images/${imagePrefix}_egg.png' : (score < 100 ? 'assets/images/${imagePrefix}_baby.png' : 'assets/images/${imagePrefix}_adult.png');
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)]),
      child: Column(
        children: [
          Image.asset(imagePath, height: 120, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 80, color: Colors.grey)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: (score >= 100) ? 1.0 : (score % 50) / 50, backgroundColor: Colors.grey[200], color: Colors.orange, minHeight: 6, borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOUVELLE PAGE : MODE FOCUS (Chronomètre Plein Écran)
// ---------------------------------------------------------------------------
class FocusTimerPage extends StatefulWidget {
  final Habit habit;
  final HabitDatabase db;

  const FocusTimerPage({super.key, required this.habit, required this.db});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  late Timer _timer;
  late int _secondsRemaining;
  late int _totalSeconds;
  bool _isRunning = true;
  bool _isFinished = false;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    // On convertit les minutes (targetValue) en secondes
    _totalSeconds = widget.habit.targetValue * 60;
    _secondsRemaining = _totalSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _finishTimer();
        }
      });
    });
  }

  void _finishTimer() {
    _timer.cancel();
    _isRunning = false;
    _isFinished = true;
    
    // On valide l'habitude dans la base de données
    widget.db.completeHabit(widget.habit);
    
    // Fête !
    _confettiController.play();
    SoundManager.play('success.mp3');
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int min = totalSeconds ~/ 60;
    int sec = totalSeconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple, // Fond immersif
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Contenu principal
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. EN-TÊTE
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    widget.habit.title,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),

                // 2. LE GROS CHRONO CENTRAL
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: _isFinished ? 1 : 1 - (_secondsRemaining / _totalSeconds),
                            strokeWidth: 15,
                            backgroundColor: Colors.white24,
                            color: _isFinished ? Colors.green : Colors.amber,
                          ),
                        ),
                        Text(
                          _isFinished ? "BRAVO !" : _formatTime(_secondsRemaining),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    if (!_isFinished)
                      Text(
                        _isRunning ? "Focus en cours..." : "Pause",
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                  ],
                ),

                // 3. BOUTONS DE CONTRÔLE
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: _isFinished
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check),
                          label: const Text("Récupérer ma récompense"),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Bouton Abandonner
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Abandonner", style: TextStyle(color: Colors.white54)),
                            ),
                            const SizedBox(width: 20),
                            // Bouton Pause/Play
                            FloatingActionButton.large(
                              backgroundColor: Colors.amber,
                              onPressed: () {
                                setState(() {
                                  _isRunning = !_isRunning;
                                  if (_isRunning) {
                                    _startTimer();
                                  } else {
                                    _timer.cancel();
                                  }
                                });
                              },
                              child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.deepPurple),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          
          // Confettis par dessus tout
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 50,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ],
      ),
    );
  }
}