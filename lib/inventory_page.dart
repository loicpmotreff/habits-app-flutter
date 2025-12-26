import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/habit_database.dart';
import 'models/items.dart'; // Import du catalogue

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mon Sac à Dos 🎒"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<HabitDatabase>(
        builder: (context, db, child) {
          // 1. On récupère la liste des objets que l'utilisateur possède
          // On filtre 'allShopItems' pour ne garder que ceux présents dans 'db.inventory'
          final myItems = allShopItems.where((item) => db.inventory.contains(item.id)).toList();

          if (myItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.backpack_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Ton sac est vide...", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      // Petite astuce pour aller à la boutique (tab 2) serait complexe ici,
                      // on laisse l'utilisateur cliquer en bas pour l'instant.
                    },
                    child: const Text("Aller à la boutique"),
                  )
                ],
              ),
            );
          }

          // 2. La Grille d'inventaire
          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: myItems.length,
            itemBuilder: (context, index) {
              final item = myItems[index];
              bool isEquipped = db.itemActive == item.id;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: isEquipped ? Border.all(color: Colors.deepPurple, width: 3) : null,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 45, color: item.color),
                    const SizedBox(height: 10),
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    
                    const SizedBox(height: 15),
                    
                    // BOUTON D'ACTION
                    if (item.type == 'skin') 
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEquipped ? Colors.green : Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Si c'est un skin, on l'équipe
                          db.setItemActive(item.id);
                        },
                        child: Text(isEquipped ? "Activé" : "Mettre"),
                      )
                    else
                      // Pour les consommables (Potion), on met un bouton inactif pour l'instant
                      OutlinedButton(
                        onPressed: null, 
                        child: Text("Utiliser", style: TextStyle(color: Colors.grey[400])),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}