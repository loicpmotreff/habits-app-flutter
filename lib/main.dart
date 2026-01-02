import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:animate_do/animate_do.dart';

// Vos imports
import 'database/habit_database.dart';
import 'models/habit.dart';
import 'profile_page.dart';
import 'sound_manager.dart';
import 'habit_details_page.dart';

// --- PALETTE "BADMINTON NIGHT" ---
const Color kNeonCyan = Color(0xFF00C2E0);      // Bleu électrique
const Color kDeepNight = Color(0xFF0A1117);     // Fond très sombre
const Color kCardNight = Color(0xFF121A21);     // Fond des cartes
const Color kTextGrey = Color(0xFFB0B8C4);      // Texte secondaire

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Initialisation de la BDD
  final habitDatabase = HabitDatabase();
  await habitDatabase.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => habitDatabase),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<HabitDatabase>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit RPG',
      
      // THÈME CLAIR (Adapté Cyan)
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        colorScheme: ColorScheme.fromSeed(seedColor: kNeonCyan, primary: kNeonCyan),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        useMaterial3: true,
      ),

      // THÈME SOMBRE (DESIGN "NIGHT CYAN")
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kDeepNight,
        
        colorScheme: const ColorScheme.dark(
          primary: kNeonCyan,
          onPrimary: Colors.black,
          secondary: kNeonCyan,
          surface: kCardNight,
          background: kDeepNight,
          onSurface: Colors.white,
        ),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: kTextGrey),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        cardTheme: CardThemeData(
          color: kCardNight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kNeonCyan,
            foregroundColor: const Color(0xFF0A1117),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kCardNight,
          indicatorColor: kNeonCyan.withOpacity(0.2),
          iconTheme: MaterialStateProperty.all(const IconThemeData(color: Colors.white)),
          labelTextStyle: MaterialStateProperty.all(const TextStyle(color: kTextGrey, fontSize: 12)),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),

      themeMode: db.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
    const HabitPage(),   // Index 0
    const ProfilePage(), // Index 1
  ];

  // --- NOUVELLE INTERFACE COMPACTE (V3.0) ---
void _showHabitDialog(BuildContext context, {Habit? habitToEdit}) {
    // --- INITIALISATION ---
    final controller = TextEditingController(text: habitToEdit?.title ?? "");
    TextEditingController targetController = TextEditingController(text: (habitToEdit?.targetValue ?? 1).toString());
    TextEditingController unitController = TextEditingController(text: habitToEdit?.unit ?? "");

    List<int> selectedDays = habitToEdit != null ? List<int>.from(habitToEdit.activeDays) : [1, 2, 3, 4, 5, 6, 7];
    bool isTimerMode = habitToEdit?.isTimer ?? false;
    bool isNegativeMode = habitToEdit?.isNegative ?? false;
    HabitCategory selectedCategory = habitToEdit?.category ?? HabitCategory.other;
    HabitDifficulty selectedDifficulty = HabitDifficulty.medium;

    // --- THEME ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: dialogColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                habitToEdit == null ? "Nouvelle quête" : "Modifier",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- 1. TITRE ---
                    TextField(
                      controller: controller,
                      autofocus: false, // On garde false pour la sécurité anti-crash
                      decoration: InputDecoration(
                        hintText: "Titre de la quête...",
                        filled: true,
                        fillColor: inputColor,
                        prefixIcon: const Icon(Icons.edit),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- 2. SWITCHS ---
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            title: const Text("Négatif", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            value: isNegativeMode,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: Colors.redAccent,
                            onChanged: (val) => setState(() { isNegativeMode = val; if(val) isTimerMode = false; }),
                          ),
                        ),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text("Chrono", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            value: isTimerMode,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: Colors.cyan,
                            onChanged: (val) => setState(() { isTimerMode = val; }),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // --- 3. CATÉGORIES (VERSION LISTE DÉROULANTE) ---
                    // C'est ici que ça change ! Plus de ListView, donc plus de crash.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: inputColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<HabitCategory>(
                          value: selectedCategory,
                          isExpanded: true, // Prend toute la largeur
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          dropdownColor: dialogColor, // Couleur du menu déroulant
                          items: HabitCategory.values.map((HabitCategory cat) {
                            final details = _getCategoryDetails(cat);
                            return DropdownMenuItem<HabitCategory>(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(details['icon'], size: 20, color: details['color']),
                                  const SizedBox(width: 10),
                                  Text(
                                    details['label'],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (HabitCategory? newValue) {
                            if (newValue != null) {
                              setState(() => selectedCategory = newValue);
                            }
                          },
                        ),
                      ),
                    ),

                    // ... juste après le Container du DropdownButton

                    if (!isNegativeMode) ...[
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: targetController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: isTimerMode ? "Min" : "Qté",
                                filled: true,
                                fillColor: inputColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: unitController,
                              enabled: !isTimerMode, // Désactivé si c'est un chrono
                              decoration: InputDecoration(
                                labelText: "Unité (ex: pages)",
                                hintText: isTimerMode ? "minutes" : "",
                                filled: true,
                                fillColor: inputColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ... juste avant la Row des jours

                    const SizedBox(height: 15),

                    // --- 4. JOURS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        int dayId = index + 1;
                        bool isSel = selectedDays.contains(dayId);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSel) {
                              if (selectedDays.length > 1) selectedDays.remove(dayId);
                            } else {
                              selectedDays.add(dayId);
                            }
                          }),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: isSel ? Colors.cyan : inputColor,
                            child: Text(
                              ["L", "M", "M", "J", "V", "S", "D"][index],
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: isSel ? Colors.black : Colors.grey
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      int target = int.tryParse(targetController.text) ?? 1;
                      String unit = isTimerMode ? "min" : unitController.text.trim();

                      if (habitToEdit == null) {
                        context.read<HabitDatabase>().addHabit(
                              controller.text, selectedDays, selectedDifficulty, selectedCategory,
                              target, unit, isTimerMode, isNegativeMode
                            );
                      } else {
                        context.read<HabitDatabase>().updateHabit(
                              habitToEdit.id, controller.text, selectedDays, selectedDifficulty, selectedCategory,
                              target, unit, isTimerMode, isNegativeMode
                            );
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Créer"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _getCategoryDetails(HabitCategory category) {
    switch (category) {
      case HabitCategory.sport: return {'label': 'Sport', 'icon': Icons.fitness_center, 'color': Colors.orange};
      case HabitCategory.work: return {'label': 'Travail', 'icon': Icons.work, 'color': Colors.blue};
      case HabitCategory.health: return {'label': 'Santé', 'icon': Icons.favorite, 'color': Colors.pink};
      case HabitCategory.art: return {'label': 'Art', 'icon': Icons.palette, 'color': Colors.purple};
      case HabitCategory.social: return {'label': 'Social', 'icon': Icons.people, 'color': Colors.teal};
      default: return {'label': 'Autre', 'icon': Icons.circle, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showHabitDialog(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text("Quête", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
          
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Quêtes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DE NIVEAU (Barre Cyan) ---
class LevelWidget extends StatelessWidget {
  final int level;
  final int currentXP;
  final int requiredXP;

  const LevelWidget({
    super.key,
    required this.level,
    required this.currentXP,
    required this.requiredXP,
  });

  @override
  Widget build(BuildContext context) {
    double progress = (requiredXP == 0) ? 0 : currentXP / requiredXP;
    if (progress > 1.0) progress = 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kNeonCyan, Color(0xFF006080)], // Dégradé Cyan -> Bleu Pétrole
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kNeonCyan.withOpacity(0.3), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MON NIVEAU", style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: Colors.white.withOpacity(0.8))),
                  Text("Niveau $level", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.bolt, color: Colors.amber, size: 30),
              )
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.black.withOpacity(0.3),
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$currentXP XP", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              Text("$requiredXP XP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

// --- PAGE DES HABITUDES ---
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
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Consumer<HabitDatabase>(
          builder: (context, db, child) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: Colors.white10) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text("${db.userScore}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Consumer<HabitDatabase>(
                builder: (context, db, child) => FadeInDown(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LevelWidget(
                      level: db.userLevel,
                      currentXP: db.currentXP,
                      requiredXP: db.xpRequiredForNextLevel,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<HabitDatabase>(
                  builder: (context, db, child) {
                    if (db.habits.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_add, size: 60, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 10),
                            Text("Aucune quête aujourd'hui...", style: TextStyle(color: Colors.grey.withOpacity(0.5))),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: db.habits.length,
                      itemBuilder: (context, index) {
                        final habit = db.habits[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          child: HabitTile(
                            habit: habit,
                            db: db,
                            confettiController: _confettiController,
                            // Accès au dialog via le parent
                            onEdit: () => context.findAncestorStateOfType<_MainScreenState>()?._showHabitDialog(context, habitToEdit: habit),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [kNeonCyan, Colors.purple, Colors.amber],
            ),
          ),
        ],
      ),
    );
  }
}

// --- TUILE D'HABITUDE ---
class HabitTile extends StatelessWidget {
  final Habit habit;
  final HabitDatabase db;
  final VoidCallback onEdit;
  final ConfettiController confettiController;

  const HabitTile({super.key, required this.habit, required this.db, required this.onEdit, required this.confettiController});

  @override
  Widget build(BuildContext context) {
    bool isSkipped = db.isHabitSkippedToday(habit);
    bool isCompleted = habit.isCompletedToday;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HabitDetailsPage(habit: habit, db: db, onEdit: onEdit)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isCompleted 
              ? (isDark ? Colors.green.withOpacity(0.1) : Colors.green[50]) 
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isCompleted ? Colors.green.withOpacity(0.5) : (isDark ? Colors.white10 : Colors.transparent)
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Checkbox Custom
            GestureDetector(
              onTap: () {
                db.updateProgress(habit, 1);
                if (!isCompleted && habit.isCompletedToday) {
                  confettiController.play();
                  SoundManager.play('success.mp3');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : (isSkipped ? Colors.grey : theme.scaffoldBackgroundColor),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSkipped ? Icons.beach_access : Icons.check,
                  color: (isCompleted || isSkipped) ? Colors.white : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(width: 15),
            
            // Textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey : theme.textTheme.bodyMedium?.color
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 14, color: Colors.orange[400]),
                      Text(" ${habit.streak} j", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 10),
                      if (habit.targetValue > 1)
                        Text(
                          "${habit.currentValue} / ${habit.targetValue} ${habit.unit}",
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                        ),
                    ],
                  )
                ],
              ),
            ),
            
            // Bouton Edit
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              onPressed: onEdit,
            )
          ],
        ),
      ),
    );
  }
}