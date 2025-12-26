import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/habit_database.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("L'Échoppe Magique ⛺"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Affichage du Solde en haut
          Consumer<HabitDatabase>(
            builder: (context, db, child) => Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Votre Bourse : ", style: TextStyle(color: Colors.white, fontSize: 18)),
                  const Icon(Icons.stars, color: Colors.amber),
                  Text(" ${db.userScore}", style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // La Grille des objets à vendre
          Expanded(
            child: GridView.count(
              crossAxisCount: 2, // 2 colonnes
              padding: const EdgeInsets.all(15),
              childAspectRatio: 0.8, // Format des cartes (plus hautes que larges)
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildShopItem(context, "Potion de Soin", "Répare un jour raté", 50, Icons.local_drink, Colors.redAccent),
                _buildShopItem(context, "Bouclier Divin", "Protège votre série", 150, Icons.shield, Colors.blueAccent),
                _buildShopItem(context, "Élixir de Force", "Double l'XP (1h)", 300, Icons.bolt, Colors.amber),
                _buildShopItem(context, "Skin Dragon", "Change l'apparence", 1000, Icons.palette, Colors.purpleAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour fabriquer une carte d'article
  Widget _buildShopItem(BuildContext context, String name, String desc, int price, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(desc, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100], elevation: 0),
            onPressed: () {
              // LOGIQUE D'ACHAT
              bool success = context.read<HabitDatabase>().buyItem(price);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Achat réussi : $name ! 🎉"), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pas assez d'argent... 😭"), backgroundColor: Colors.red),
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("$price ", style: const TextStyle(color: Colors.black)),
                const Icon(Icons.stars, size: 16, color: Colors.amber),
              ],
            ),
          )
        ],
      ),
    );
  }
}