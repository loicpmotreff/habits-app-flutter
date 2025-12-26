import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/habit_database.dart';

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
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const HabitPage(),
    );
  }
}

class HabitPage extends StatelessWidget {
  const HabitPage({super.key});

  void _createNewHabit(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouvelle quête"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Ex: Lire 10 pages"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<HabitDatabase>().addHabit(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Consumer<HabitDatabase>(
          builder: (context, db, child) {
            // Affiche le score dans la barre du haut
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 32),
                const SizedBox(width: 8),
                Text(
                  "${db.userScore} Pièces",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewHabit(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<HabitDatabase>(
        builder: (context, db, child) {
          if (db.habits.isEmpty) {
            return const Center(child: Text("Aucune habitude... Commence ta quête !"));
          }

          return ListView.builder(
            itemCount: db.habits.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final habit = db.habits[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  
                  // La Case à cocher
                  leading: Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: habit.isCompletedToday,
                      activeColor: Colors.deepPurple,
                      shape: const CircleBorder(), // Rond c'est plus moderne
                      onChanged: (value) => db.toggleHabit(habit),
                    ),
                  ),
                  
                  // Le Titre
                  title: Text(
                    habit.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      decoration: habit.isCompletedToday
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: habit.isCompletedToday ? Colors.grey : Colors.black87,
                    ),
                  ),

                  // Le Streak (La flamme)
                  subtitle: habit.streak > 0 
                    ? Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                          Text(" ${habit.streak} jours", style: const TextStyle(color: Colors.orange)),
                        ],
                      )
                    : const Text("Commence la série !"),

                  // Bouton supprimer
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                    onPressed: () => db.deleteHabit(habit),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}