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

// --- PALETTE "BADMINTON NIGHT" ---
const Color kNeonCyan = Color(0xFF00C2E0);      // Le bleu électrique du bouton
const Color kDeepNight = Color(0xFF0A1117);     // Le fond très sombre
const Color kCardNight = Color(0xFF121A21);     // Le fond des cartes (légèrement plus clair)
const Color kTextGrey = Color(0xFFB0B8C4);      // Le texte secondaire

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
    final db = context.watch<HabitDatabase>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Pet RPG',
      
      // --- THÈME CLAIR (On le garde harmonisé en Cyan) ---
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kNeonCyan,
          primary: kNeonCyan,
          secondary: const Color(0xFF0B4F6C),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        useMaterial3: true,
      ),

      // --- THÈME SOMBRE (LE DESIGN DE L'IMAGE) ---
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kDeepNight, // Fond #0A1117
        
        // Configuration des couleurs principales
        colorScheme: const ColorScheme.dark(
          primary: kNeonCyan,          // Les boutons et actions en Cyan
          onPrimary: Colors.black,     // Texte sur le Cyan (en noir pour le contraste)
          secondary: kNeonCyan,
          surface: kCardNight,         // Couleur des cartes
          background: kDeepNight,
          onSurface: Colors.white,
        ),

        // Style des Textes (Pour avoir le blanc et le gris de l'image)
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: kTextGrey),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        // Style des Cartes (Les blocs "Diplômé" / "98%")
        cardTheme: CardThemeData(
          color: kCardNight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1), // Bordure très subtile
          ),
        ),
        
        // Style des Boutons (Le bouton "Découvrir" de l'image)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kNeonCyan,
            foregroundColor: const Color(0xFF0A1117), // Texte sombre sur bouton cyan
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Style de la barre du bas
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

  // LISTE DES PAGES (2 Onglets seulement)
  final List<Widget> _pages = [
    const HabitPage(),   // Index 0 : Tes habitudes
    const ProfilePage(), // Index 1 : Tes badges, niveaux et accès paramètres
  ];

  // --- NOUVELLE INTERFACE DE CRÉATION (V2.0) ---
  void _showHabitDialog(BuildContext context, {Habit? habitToEdit}) {
    final controller = TextEditingController(text: habitToEdit?.title ?? "");
    List<int> selectedDays = habitToEdit != null ? List<int>.from(habitToEdit.activeDays) : [1, 2, 3, 4, 5, 6, 7];
    HabitDifficulty selectedDifficulty = HabitDifficulty.medium;
    HabitCategory selectedCategory = habitToEdit?.category ?? HabitCategory.other;
    TextEditingController targetController = TextEditingController(text: (habitToEdit?.targetValue ?? 1).toString());
    TextEditingController unitController = TextEditingController(text: habitToEdit?.unit ?? "");
    
    bool isTimerMode = habitToEdit?.isTimer ?? false;
    bool isNegativeMode = habitToEdit?.isNegative ?? false;

    // Couleurs adaptatives au thème
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final subTextColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final inputFillColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),

              // --- TITRE ---
              title: Center(
                child: Text(
                  habitToEdit == null ? "Nouvelle quête" : "Modifier la quête",
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ),

              // --- CONTENU ---
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. CHAMP TITRE
                    TextField(
                      controller: controller,
                      style: TextStyle(color: textColor, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: "Donne un nom à ta quête...",
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(Icons.edit, color: theme.colorScheme.primary),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                      autofocus: habitToEdit == null,
                    ),
                    const SizedBox(height: 24),

                    // 2. SECTION TYPE
                    Container(
                      decoration: BoxDecoration(
                        color: inputFillColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text("À éviter (Mauvaise habitude) 🚭", style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text("Commence validé. Décoche si tu craques !", style: TextStyle(color: subTextColor, fontSize: 12)),
                            value: isNegativeMode,
                            activeColor: Colors.redAccent,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            onChanged: (val) => setState(() { isNegativeMode = val; if (isNegativeMode) isTimerMode = false; }),
                          ),
                          if (!isNegativeMode) ...[
                             Divider(height: 1, color: borderColor),
                            SwitchListTile(
                              title: const Text("Mode Chronomètre ⏱️", style: TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text("Pour les activités basées sur le temps.", style: TextStyle(color: subTextColor, fontSize: 12)),
                              value: isTimerMode,
                              activeColor: theme.colorScheme.primary,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onChanged: (val) => setState(() { isTimerMode = val; if (isTimerMode && unitController.text.isEmpty) unitController.text = "min"; }),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 3. SECTION OBJECTIFS
                    if (!isNegativeMode) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, "Objectif", Icons.ads_click),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: targetController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: isTimerMode ? "Durée" : "Quantité",
                                labelStyle: TextStyle(color: subTextColor),
                                filled: true, fillColor: inputFillColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: unitController,
                              enabled: !isTimerMode,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: "Unité (ex: pages)",
                                labelStyle: TextStyle(color: subTextColor),
                                hintText: isTimerMode ? "minutes" : "",
                                filled: true, fillColor: inputFillColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // 4. SECTION CATÉGORIE
                    _buildSectionTitle(context, "Catégorie", Icons.category),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: HabitCategory.values.map((cat) {
                          final details = _getCategoryDetails(cat);
                          bool isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(details['label']),
                              labelStyle: TextStyle(color: isSelected ? Colors.white : textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                              avatar: Icon(details['icon'], size: 16, color: isSelected ? Colors.white : details['color']),
                              selected: isSelected,
                              selectedColor: details['color'],
                              checkmarkColor: Colors.white,
                              backgroundColor: inputFillColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onSelected: (selected) { if (selected) setState(() => selectedCategory = cat); },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // 5. SECTION FRÉQUENCE
                    _buildSectionTitle(context, "Fréquence", Icons.calendar_today),
                    const SizedBox(height: 12),
                    Container(
                       padding: const EdgeInsets.symmetric(vertical: 8),
                       decoration: BoxDecoration(color: inputFillColor, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (index) {
                          int dayId = index + 1;
                          List<String> dl = ["L", "M", "M", "J", "V", "S", "D"];
                          bool isSel = selectedDays.contains(dayId);
                          return GestureDetector(
                            onTap: () => setState(() => isSel ? (selectedDays.length > 1 ? selectedDays.remove(dayId) : null) : selectedDays.add(dayId)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isSel ? theme.colorScheme.primary : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSel ? theme.colorScheme.primary : borderColor, width: 2)
                              ),
                              alignment: Alignment.center,
                              child: Text(dl[index], style: TextStyle(color: isSel ? Colors.white : textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          );
                        }),
                      ),
                    )
                  ],
                ),
              ),

              // --- ACTIONS ---
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: subTextColor),
                        child: const Text("Annuler"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4, shadowColor: theme.colorScheme.primary.withOpacity(0.4)
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
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Sauvegarder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper pour l'affichage
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyMedium?.color)),
      ],
    );
  }
  
  // Helper pour les icônes de catégorie
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
      
      // On utilise IndexedStack pour garder l'état des pages (ne pas recharger à chaque switch)
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      // Le bouton flottant ne s'affiche que sur la page "Quêtes" (Index 0)
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showHabitDialog(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Quête", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
          
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
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
    HabitDifficulty selectedDifficulty = HabitDifficulty.medium;
    HabitCategory selectedCategory = habitToEdit?.category ?? HabitCategory.other;
    TextEditingController targetController = TextEditingController(text: (habitToEdit?.targetValue ?? 1).toString());
    TextEditingController unitController = TextEditingController(text: habitToEdit?.unit ?? "");
    
    bool isTimerMode = habitToEdit?.isTimer ?? false;
    bool isNegativeMode = habitToEdit?.isNegative ?? false;

    // Couleurs adaptatives au thème
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final subTextColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    // Couleur de fond des champs de saisie : légèrement plus clair/foncé que la carte
    final inputFillColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    // Couleur de bordure subtile
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;


    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              // Fond et forme de la boîte de dialogue
              backgroundColor: theme.cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),

              // --- TITRE ---
              title: Center(
                child: Text(
                  habitToEdit == null ? "Nouvelle quête" : "Modifier la quête",
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ),

              // --- CONTENU ---
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. CHAMP TITRE
                    TextField(
                      controller: controller,
                      style: TextStyle(color: textColor, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: "Ex : Sport, méditer ...",
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(Icons.edit, color: theme.colorScheme.primary),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                      autofocus: habitToEdit == null,
                    ),
                    const SizedBox(height: 24),

                    // 2. SECTION TYPE (Switchs)
                    Container(
                      decoration: BoxDecoration(
                        color: inputFillColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          // SWITCH : NÉGATIF
                          SwitchListTile(
                            title: const Text("À éviter (Mauvaise habitude) 🚭", style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text("Commence validé. Décoche si tu craques !", style: TextStyle(color: subTextColor, fontSize: 12)),
                            value: isNegativeMode,
                            activeColor: Colors.redAccent,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            onChanged: (val) => setState(() { isNegativeMode = val; if (isNegativeMode) isTimerMode = false; }),
                          ),
                          if (!isNegativeMode) ...[
                             Divider(height: 1, color: borderColor),
                            // SWITCH : CHRONO
                            SwitchListTile(
                              title: const Text("Mode Chronomètre ⏱️", style: TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text("Pour les activités basées sur le temps.", style: TextStyle(color: subTextColor, fontSize: 12)),
                              value: isTimerMode,
                              activeColor: theme.colorScheme.primary,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onChanged: (val) => setState(() { isTimerMode = val; if (isTimerMode && unitController.text.isEmpty) unitController.text = "min"; }),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 3. SECTION OBJECTIFS (Cachée si Négatif)
                    if (!isNegativeMode) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, "Objectif", Icons.ads_click),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Objectif (Chiffre)
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: targetController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: isTimerMode ? "Durée" : "Quantité",
                                labelStyle: TextStyle(color: subTextColor),
                                filled: true, fillColor: inputFillColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Unité (Texte)
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: unitController,
                              enabled: !isTimerMode,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: "Unité (ex: pages, verres)",
                                labelStyle: TextStyle(color: subTextColor),
                                hintText: isTimerMode ? "minutes" : "",
                                filled: true, fillColor: inputFillColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // 4. SECTION CATÉGORIE
                    _buildSectionTitle(context, "Catégorie", Icons.category),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: HabitCategory.values.map((cat) {
                          final details = _getCategoryDetails(cat);
                          bool isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip( // Utilisation de FilterChip pour un look plus moderne
                              label: Text(details['label']),
                              labelStyle: TextStyle(color: isSelected ? Colors.white : textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                              avatar: Icon(details['icon'], size: 16, color: isSelected ? Colors.white : details['color']),
                              selected: isSelected,
                              selectedColor: details['color'],
                              checkmarkColor: Colors.white,
                              backgroundColor: inputFillColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onSelected: (selected) { if (selected) setState(() => selectedCategory = cat); },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // 5. SECTION FRÉQUENCE
                    _buildSectionTitle(context, "Fréquence", Icons.calendar_today),
                    const SizedBox(height: 12),
                    Container(
                       padding: const EdgeInsets.symmetric(vertical: 8),
                       decoration: BoxDecoration(
                         color: inputFillColor,
                         borderRadius: BorderRadius.circular(16),
                       ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (index) {
                          int dayId = index + 1;
                          List<String> dl = ["L", "M", "M", "J", "V", "S", "D"];
                          bool isSel = selectedDays.contains(dayId);
                          return GestureDetector(
                            onTap: () => setState(() => isSel ? (selectedDays.length > 1 ? selectedDays.remove(dayId) : null) : selectedDays.add(dayId)),
                            child: AnimatedContainer( // Animation douce au clic
                              duration: const Duration(milliseconds: 200),
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isSel ? theme.colorScheme.primary : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSel ? theme.colorScheme.primary : borderColor, width: 2)
                              ),
                              alignment: Alignment.center,
                              child: Text(dl[index], style: TextStyle(color: isSel ? Colors.white : textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          );
                        }),
                      ),
                    )
                  ],
                ),
              ),

              // --- ACTIONS ---
              actions: [
                Row(
                  children: [
                    // Bouton Annuler
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: subTextColor),
                        child: const Text("Annuler"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton Sauvegarder
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4, shadowColor: theme.colorScheme.primary.withOpacity(0.4)
                        ),
                        onPressed: () {
                          // (Logique de sauvegarde inchangée)
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
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Sauvegarder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Petit helper pour les titres de section
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyMedium?.color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
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

    // 1. ON DÉTECTE SI ON EST EN MODE SOMBRE
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. ON DÉFINIT LES COULEURS INTELLIGENTES
    // Couleur du fond de la carte (Blanc le jour, Gris foncé la nuit)
    Color cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    // Couleur du fond si "Joker" (Gris clair le jour, Gris moyen la nuit)
    Color skippedColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    // Couleur du texte (Noir le jour, Blanc la nuit)
    Color textColor = isDark ? Colors.white : Colors.black87;

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
        // 3. ON UTILISE NOS COULEURS INTELLIGENTES ICI (Ligne 454 sur votre image)
        color: isSkipped ? skippedColor : cardColor, 
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: mainColor, width: 6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        
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
                        } else if (val == true) {
                          confettiController.play();
                          SoundManager.play('success.mp3');
                        }
                      },
                    ),
                  )
                : null),

        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HabitDetailsPage(
                  habit: habit,
                  db: db,
                  onEdit: onEdit,
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
                  // 4. ON APPLIQUE LA COULEUR DU TEXTE ICI (Sinon le texte noir sur fond noir ne se voit pas)
                  color: (habit.isCompletedToday && !habit.isNegative) || isSkipped ? Colors.grey : textColor,
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
                  // 5. TEXTE DU COMPTEUR ADAPTATIF
                  Text("${habit.currentValue}/${habit.targetValue} ${habit.unit}", style: TextStyle(fontWeight: FontWeight.bold, color: isSkipped ? Colors.grey : textColor)),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        // DÉGRADÉ CYAN -> BLEU NUIT
        gradient: const LinearGradient(
          colors: [kNeonCyan, Color(0xFF006080)], // Cyan vers un bleu pétrole plus sombre
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        // L'effet de brillance (Glow) cyan sous la carte
        boxShadow: [
          BoxShadow(
            color: kNeonCyan.withOpacity(0.3), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
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