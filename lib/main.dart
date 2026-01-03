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
import 'package:flutter/cupertino.dart';  

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
          iconTheme: WidgetStateProperty.all(const IconThemeData(color: Colors.white)),
          labelTextStyle: WidgetStateProperty.all(const TextStyle(color: kTextGrey, fontSize: 12)),
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
    // --- 1. INITIALISATION DES CONTROLEURS & VARIABLES ---
    final controller = TextEditingController(text: habitToEdit?.title ?? "");
    
    // Logique Chrono (Conversion en Min/Sec pour l'affichage)
    int totalSeconds = (habitToEdit?.isTimer ?? false) ? (habitToEdit?.targetValue ?? 300) : 300;
    // Si on édite une habitude qui n'était pas un timer, on met 5 min par défaut
    if (!(habitToEdit?.isTimer ?? false) && habitToEdit != null) totalSeconds = 300;
    
    TextEditingController minController = TextEditingController(text: (totalSeconds ~/ 60).toString());
    TextEditingController secController = TextEditingController(text: (totalSeconds % 60).toString());

    // Logique Quantité Classique
    TextEditingController targetController = TextEditingController(text: (habitToEdit?.targetValue ?? 1).toString());
    TextEditingController unitController = TextEditingController(text: habitToEdit?.unit ?? "");

    // Logique Fréquence & Jours
    List<int> selectedDays = habitToEdit != null ? List<int>.from(habitToEdit.activeDays) : [1, 2, 3, 4, 5, 6, 7];
    
    // --- NOUVEAUX CHAMPS FLEXIBLES ---
    // (Note : Il faudra que 'habitToEdit' possède ces champs après ta mise à jour de Hive)
    // Pour l'instant on met des valeurs par défaut si ça n'existe pas encore
    bool isFrequencyFlexible = false; 
    int frequencyGoal = 3; 
    
    // Si tu as déjà mis à jour habit.dart, tu pourras décommenter ça plus tard :
    // isFrequencyFlexible = habitToEdit?.isFlexible ?? false;
    // frequencyGoal = habitToEdit?.weeklyGoal ?? 3;

    bool isTimerMode = habitToEdit?.isTimer ?? false;
    bool isNegativeMode = habitToEdit?.isNegative ?? false;
    HabitCategory selectedCategory = habitToEdit?.category ?? HabitCategory.other;
    HabitDifficulty selectedDifficulty = HabitDifficulty.medium;

    // --- 2. THEME & STYLES ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;
    final labelStyle = TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold);
    final activeColor = Colors.cyan;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: dialogColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.all(24),
              
              // --- TITRE ---
              title: Text(
                habitToEdit == null ? "Créer une Quête" : "Modifier",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- SECTION 1 : IDENTITÉ ---
                    Text("TITRE", style: labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      autofocus: false, // Sécurité anti-crash clavier
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Ex: Lire, Courir...",
                        filled: true, fillColor: inputColor,
                        prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Dropdown Catégorie
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: inputColor, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<HabitCategory>(
                          value: selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          dropdownColor: dialogColor,
                          items: HabitCategory.values.map((cat) {
                            final details = _getCategoryDetails(cat);
                            return DropdownMenuItem(
                              value: cat, 
                              child: Row(
                                children: [
                                  Icon(details['icon'], size: 18, color: details['color']), 
                                  const SizedBox(width: 10), 
                                  Text(details['label'], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14))
                                ]
                              )
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedCategory = val!),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- SECTION 2 : OPTIONS ---
                    Text("TYPE", style: labelStyle),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: inputColor, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text("Mauvaise habitude", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: isNegativeMode,
                            activeColor: Colors.redAccent,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            onChanged: (val) => setState(() { isNegativeMode = val; if(val) isTimerMode = false; }),
                          ),
                          Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                          SwitchListTile(
                            title: const Text("Chronomètre", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: isTimerMode,
                            activeColor: activeColor,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            onChanged: (val) => setState(() { isTimerMode = val; if(val) isNegativeMode = false; }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- SECTION 3 : OBJECTIF ---
                    if (isTimerMode) ...[
                      // Mode Timer (Min : Sec)
                      Text("DURÉE", style: labelStyle),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: minController, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.cyan), decoration: InputDecoration(labelText: "Min", filled: true, fillColor: inputColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey))),
                          Expanded(child: TextField(controller: secController, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.cyan), decoration: InputDecoration(labelText: "Sec", filled: true, fillColor: inputColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                        ],
                      ),
                    ] else if (!isNegativeMode) ...[
                      // Mode Quantité
                      Text("OBJECTIF", style: labelStyle),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(flex: 1, child: TextField(controller: targetController, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), decoration: InputDecoration(labelText: "Qté", filled: true, fillColor: inputColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                          const SizedBox(width: 10),
                          Expanded(flex: 2, child: TextField(controller: unitController, decoration: InputDecoration(labelText: "Unité (ex: km)", filled: true, fillColor: inputColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // --- SECTION 4 : FRÉQUENCE ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("FRÉQUENCE", style: labelStyle),
                        // Switch Jours / Flexible
                        Container(
                          height: 30,
                          decoration: BoxDecoration(color: inputColor, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => isFrequencyFlexible = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: !isFrequencyFlexible ? activeColor : null, borderRadius: BorderRadius.circular(8)),
                                  child: Text("Jours", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: !isFrequencyFlexible ? Colors.black : Colors.grey)),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => isFrequencyFlexible = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: isFrequencyFlexible ? activeColor : null, borderRadius: BorderRadius.circular(8)),
                                  child: Text("Flexible", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isFrequencyFlexible ? Colors.black : Colors.grey)),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Contenu dynamique Fréquence
                    if (!isFrequencyFlexible) 
                      // --- CAS 1 : JOURS FIXES ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          int dayId = index + 1;
                          bool isSel = selectedDays.contains(dayId);
                          return GestureDetector(
                            onTap: () => setState(() {
                              isSel ? (selectedDays.length > 1 ? selectedDays.remove(dayId) : null) : selectedDays.add(dayId);
                            }),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: isSel ? activeColor : inputColor,
                              child: Text(["L", "M", "M", "J", "V", "S", "D"][index], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSel ? Colors.black : Colors.grey)),
                            ),
                          );
                        }),
                      )
                    else 
                      // --- CAS 2 : MODE FLEXIBLE (CORRIGÉ AVEC EXPANDED) ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: inputColor, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Texte flexible qui prend la place dispo sans pousser
                            const Expanded(
                              child: Text(
                                "Objectif / semaine :", 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Boutons Compteurs Compacts
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => setState(() { if(frequencyGoal > 1) frequencyGoal--; }), 
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Colors.grey,
                                  constraints: const BoxConstraints(), // Réduit la taille du bouton
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                Container(
                                  width: 30,
                                  alignment: Alignment.center,
                                  child: Text("$frequencyGoal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: activeColor)),
                                ),
                                IconButton(
                                  onPressed: () => setState(() { if(frequencyGoal < 7) frequencyGoal++; }), 
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: activeColor,
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // --- ACTIONS ---
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor, 
                      foregroundColor: Colors.black, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        // --- CALCULS PRÉLIMINAIRES ---
                        int target;
                        String unit;
                        
                        // Calcul Target (Chrono ou Qté)
                        if (isTimerMode) {
                          int m = int.tryParse(minController.text) ?? 0;
                          int s = int.tryParse(secController.text) ?? 0;
                          target = (m * 60) + s;
                          if (target == 0) target = 60; 
                          unit = "sec";
                        } else {
                          target = int.tryParse(targetController.text) ?? 1;
                          unit = unitController.text.trim();
                        }

                        // --- APPEL A LA BASE DE DONNÉES CORRIGÉ ---
                        // On passe maintenant les variables isFrequencyFlexible et frequencyGoal
                        
                        if (habitToEdit == null) {
                          context.read<HabitDatabase>().addHabit(
                            controller.text, 
                            selectedDays, 
                            selectedDifficulty, 
                            selectedCategory, 
                            target, 
                            unit, 
                            isTimerMode, 
                            isNegativeMode,
                            isFrequencyFlexible, // ✅ Ajouté (correspond à isFlexible)
                            frequencyGoal        // ✅ Ajouté (correspond à weeklyGoal)
                          );
                        } else {
                          context.read<HabitDatabase>().updateHabit(
                            habitToEdit.id, 
                            controller.text, 
                            selectedDays, 
                            selectedDifficulty, 
                            selectedCategory, 
                            target, 
                            unit, 
                            isTimerMode, 
                            isNegativeMode,
                            isFrequencyFlexible, // ✅ Ajouté
                            frequencyGoal        // ✅ Ajouté
                          );
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Valider", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      // --- REMPLACE LES LIGNES 814 et 815 PAR CECI ---
                    
                    if (habit.isFlexible) ...[
                      // CAS FLEXIBLE : Icône de boucle + Progression (ex: 1/3)
                      const Icon(Icons.sync_alt, size: 14, color: Colors.cyan),
                      const SizedBox(width: 4),
                      Builder(builder: (context) {
                         // On calcule la progression de la semaine
                         final progress = context.read<HabitDatabase>().getWeeklyProgress(habit);
                         return Text(
                           "$progress / ${habit.weeklyGoal} sem.",
                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                         );
                      }),
                    ] else ...[
                      // CAS NORMAL : Flamme + Série
                      Icon(Icons.local_fire_department, size: 14, color: Colors.orange[400]),
                      Text(" ${habit.streak} j", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
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