import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';

import 'database/habit_database.dart';
import 'models/habit.dart';
import 'shop_page.dart';
import 'inventory_page.dart';
import 'profile_page.dart';
import 'sound_manager.dart';
import 'habit_details_page.dart'; 

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
      
      // --- DÉBUT DU THÈME BLEU ---
      theme: ThemeData(
        // 1. La couleur de base (génère toutes les nuances)
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade800, // Bleu profond
          secondary: Colors.tealAccent.shade700, // Couleur secondaire
          surface: Colors.white, // Couleur des cartes
          background: const Color(0xFFF5F7FA), // Couleur de fond gris-bleuté
        ),
        
        // 2. Couleur de fond de l'application (Scaffold)
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        
        // 3. Style des AppBars
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.black87),
        ),

        // 4. Style des cartes (Card / Container)
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        
        // 5. Style Material 3 activé
        useMaterial3: true,
      ),
      // --- FIN DU THÈME ---
      
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
        indicatorColor: Colors.blue.shade200, 
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
    // On force la difficulté à "Moyen" par défaut car on retire le sélecteur
    HabitDifficulty selectedDifficulty = HabitDifficulty.medium; 
    HabitCategory selectedCategory = habitToEdit?.category ?? HabitCategory.other;
    TextEditingController targetController = TextEditingController(text: (habitToEdit?.targetValue ?? 1).toString());
    TextEditingController unitController = TextEditingController(text: habitToEdit?.unit ?? "");
    
    bool isTimerMode = habitToEdit?.isTimer ?? false;
    bool isNegativeMode = habitToEdit?.isNegative ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Coins arrondis
              title: Text(habitToEdit == null ? "Nouvelle quête" : "Modifier", style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller, 
                      decoration: const InputDecoration(
                        hintText: "Titre", 
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ), 
                      autofocus: true
                    ),
                    const SizedBox(height: 15),

                    // SWITCH : HABITUDE NÉGATIVE
                    SwitchListTile(
                      title: const Text("À éviter (Négatif) 🚭", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("Coché par défaut."),
                      value: isNegativeMode,
                      activeColor: Colors.red, // On garde rouge pour le danger
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          isNegativeMode = val;
                          if (isNegativeMode) isTimerMode = false;
                        });
                      },
                    ),

                    // SWITCH : CHRONO (Caché si Négatif)
                    if (!isNegativeMode) ...[
                      const Divider(),
                      SwitchListTile(
                        title: const Text("Mode Chronomètre ⏱️", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text("Lancer un compte à rebours"),
                        value: isTimerMode,
                        activeColor: Colors.blue.shade700, // BLEU ICI 🔵
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            isTimerMode = val;
                            if (isTimerMode && unitController.text.isEmpty) unitController.text = "min";
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 15),

                    // CHAMPS OBJECTIF (Cachés si Négatif)
                    if (!isNegativeMode)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: targetController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: isTimerMode ? "Durée" : "Objectif",
                                helperText: isTimerMode ? "en minutes" : "ex: 5",
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
                                helperText: isTimerMode ? "Auto" : "ex: verres",
                                hintText: isTimerMode ? "minutes" : "fois",
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // CATÉGORIES
                    const Align(alignment: Alignment.centerLeft, child: Text("Catégorie", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const SizedBox(height: 8),
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
                              selectedColor: details['color'], // On garde la couleur de la catégorie
                              backgroundColor: Colors.grey[100],
                              onSelected: (selected) { if (selected) setState(() => selectedCategory = cat); },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),
                    
                    // FRÉQUENCE (JOURS)
                    const Align(alignment: Alignment.centerLeft, child: Text("Fréquence", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      children: List.generate(7, (index) {
                        int dayId = index + 1;
                        List<String> dl = ["L", "M", "M", "J", "V", "S", "D"];
                        bool isSel = selectedDays.contains(dayId);
                        return GestureDetector(
                          onTap: () => setState(() => isSel ? (selectedDays.length > 1 ? selectedDays.remove(dayId) : null) : selectedDays.add(dayId)),
                          child: CircleAvatar(
                            radius: 16, 
                            backgroundColor: isSel ? Colors.blue.shade700 : Colors.grey[200], // BLEU ICI 🔵
                            child: Text(dl[index], style: TextStyle(color: isSel ? Colors.white : Colors.black, fontSize: 12))
                          ),
                        );
                      }),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700, // BOUTON BLEU 🔵
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      int target = int.tryParse(targetController.text) ?? 1;
                      if (target < 1) target = 1;
                      String unit = isTimerMode ? "min" : unitController.text.trim();

                      if (habitToEdit == null) {
                        context.read<HabitDatabase>().addHabit(controller.text, selectedDays, selectedDifficulty, selectedCategory, target, unit, isTimerMode, isNegativeMode);
                      } else {
                        context.read<HabitDatabase>().updateHabit(habitToEdit.id, controller.text, selectedDays, selectedDifficulty, selectedCategory, target, unit, isTimerMode, isNegativeMode);
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
              backgroundColor: Colors.blue.shade700, // <--- ICI (Au lieu de deepPurple)
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Quête", style: TextStyle(color: Colors.white)),
            ),
            body: Consumer<HabitDatabase>(
              builder: (context, db, child) {
                return Column(
                  children: [
                    ElasticIn(child: LevelWidget(level: db.userLevel, currentXP: db.currentXP, requiredXP: db.xpRequiredForNextLevel,)),
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
// WIDGET HABIT TILE
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// WIDGET HABIT TILE (Mise à jour : Gestion visuelle du Joker)
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// WIDGET HABIT TILE (Version Finale : Stats + Joker + Chrono)
// ---------------------------------------------------------------------------
class HabitTile extends StatelessWidget {
  final Habit habit;
  final HabitDatabase db;
  final VoidCallback onEdit;
  final ConfettiController confettiController;

  const HabitTile({super.key, required this.habit, required this.db, required this.onEdit, required this.confettiController});

  @override
  Widget build(BuildContext context) {
    bool isSkipped = db.isHabitSkippedToday(habit);

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
    Color mainColor = isSkipped ? Colors.grey : (habit.isNegative ? Colors.red : details['color']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSkipped ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: mainColor, width: 6)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        
        // --- GAUCHE (ACTIONS) ---
        leading: habit.isTimer
            ? IconButton(
                icon: Icon(
                  habit.isCompletedToday ? Icons.check_circle : Icons.play_circle_fill,
                  color: habit.isCompletedToday ? Colors.green : mainColor,
                  size: 34,
                ),
                onPressed: () {
                  if (isSkipped) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🏖️ Mode Joker activé - Repose-toi !"), duration: Duration(seconds: 1)));
                    return;
                  }
                  if (!habit.isCompletedToday) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FocusTimerPage(habit: habit, db: db)));
                  }
                },
              )
            : (!isCounter
                ? Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: habit.isCompletedToday,
                      activeColor: habit.isNegative ? Colors.green : mainColor,
                      shape: const CircleBorder(),
                      onChanged: (val) {
                        if (isSkipped) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🏖️ Mode Joker activé - Repose-toi !"), duration: Duration(seconds: 1)));
                          return;
                        }
                        int change = val == true ? 1 : -1;
                        db.updateProgress(habit, change);
                        
                        if (habit.isNegative && val == false) {
                           // Son échec
                        } else if (val == true) {
                          confettiController.play();
                          SoundManager.play('success.mp3');
                        }
                      },
                    ),
                  )
                : null),

        // --- CENTRE (TITRE + NAVIGATION VERS STATS) ---
        title: GestureDetector(
          // C'EST ICI LA CORRECTION : On ouvre la page de détails !
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HabitDetailsPage(
                  habit: habit,
                  db: db,
                  onEdit: onEdit, // On passe la main à la page de détails pour modifier
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: (habit.isCompletedToday && !habit.isNegative) ? TextDecoration.lineThrough : null,
                  color: (habit.isCompletedToday && !habit.isNegative) || isSkipped ? Colors.grey[400] : Colors.black87,
                ),
              ),
              if (isSkipped)
                const Text("🏖️ Mode Joker activé", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))
              else if (habit.isTimer)
                Text(habit.isCompletedToday ? "Terminé !" : "${habit.targetValue} min", style: TextStyle(color: Colors.grey[600], fontSize: 12))
              else if (habit.streak > 0)
                 Row(children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                    Text(" ${habit.streak} j", style: TextStyle(color: Colors.orange[700], fontSize: 12)),
                 ]),
            ],
          ),
        ),

        // --- DROITE (COMPTEUR OU FLECHE) ---
        trailing: isCounter
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                       if (isSkipped) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🏖️ Mode Joker activé")));
                          return;
                       }
                       db.updateProgress(habit, -1);
                    },
                  ),
                  Text("${habit.currentValue}/${habit.targetValue} ${habit.unit}", style: TextStyle(fontWeight: FontWeight.bold, color: isSkipped ? Colors.grey : Colors.black)),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: isSkipped ? Colors.grey : mainColor),
                    onPressed: () {
                      if (isSkipped) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🏖️ Mode Joker activé")));
                          return;
                       }
                      db.updateProgress(habit, 1);
                      if (habit.currentValue + 1 >= habit.targetValue && !habit.isCompletedToday) {
                         confettiController.play();
                         SoundManager.play('success.mp3');
                      }
                    },
                  ),
                ],
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
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
    _totalSeconds = widget.habit.targetValue * 60;
    _secondsRemaining = _totalSeconds;
    _startTimer();
  }

  String _getPetImagePath() {
    String activeSkin = widget.db.itemActive;
    int score = widget.db.userScore;
    String imagePrefix = activeSkin != 'default' ? activeSkin : "pet";
    if (score < 50) return 'assets/images/${imagePrefix}_egg.png';
    if (score < 100) return 'assets/images/${imagePrefix}_baby.png';
    return 'assets/images/${imagePrefix}_adult.png';
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
    widget.db.completeHabit(widget.habit);
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
      backgroundColor: Colors.deepPurple,
      body: Stack(
        alignment: Alignment.center,
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    widget.habit.title,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Center(
                  child: _isFinished
                      ? FadeInUp(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                _getPetImagePath(),
                                height: 180,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(Icons.emoji_events, size: 150, color: Colors.amber),
                              ),
                              const SizedBox(height: 30),
                              const Text("BRAVO ! 🎉", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text("Tu as assuré !", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 20)),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: CircularProgressIndicator(
                                    value: 1 - (_secondsRemaining / _totalSeconds),
                                    strokeWidth: 15,
                                    backgroundColor: Colors.white24,
                                    color: Colors.amber,
                                  ),
                                ),
                                Text(_formatTime(_secondsRemaining), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Text(_isRunning ? "Focus en cours..." : "Pause", style: const TextStyle(color: Colors.white70, fontSize: 18)),
                          ],
                        ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
                  child: _isFinished
                      ? FadeInUp(
                          delay: const Duration(milliseconds: 500),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 8),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.check_circle, size: 28),
                              label: const Text("Récupérer ma récompense"),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abandonner", style: TextStyle(color: Colors.white54))),
                            const SizedBox(width: 20),
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

// ---------------------------------------------------------------------------
// WIDGET NIVEAU (Barre d'XP)
// ---------------------------------------------------------------------------
class LevelWidget extends StatelessWidget {
  final int level;
  final int currentXP;
  final int requiredXP;
  
  const LevelWidget({
    super.key, 
    required this.level, 
    required this.currentXP, 
    required this.requiredXP
  });

  @override
  Widget build(BuildContext context) {
    // Calcul du pourcentage (0.0 à 1.0)
    double progress = currentXP / requiredXP;
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade500], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        children: [
          // Ligne du haut : Niveau et Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("MON NIVEAU", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
                  Text(
                    "Niveau $level", 
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Colors.amber, size: 30),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 15,
              backgroundColor: Colors.black26,
              color: Colors.amber, // Couleur de l'XP
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Texte XP en dessous
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("0 XP", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Text(
                "$currentXP / $requiredXP XP", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ],
          )
        ],
      ),
    );
  }
}







// LE RESTE (PetWidget) est pareil qu'avant, tu peux laisser tel quel si c'est déjà là.
/*class PetWidget extends StatelessWidget {
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
}*/