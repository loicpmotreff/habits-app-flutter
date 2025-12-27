import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/habit_database.dart';
import 'models/items.dart'; // Assurez-vous que ce fichier existe
import 'sound_manager.dart';

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
          // 1. LE SCORE (Sans 'const' devant Row car le score change)
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
                  Text(
                    " ${db.userScore}", 
                    style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          ),

          // 2. LA GRILLE AUTOMATIQUE
          Expanded(
            child: Consumer<HabitDatabase>(
              builder: (context, db, child) {
                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: allShopItems.length,
                  // C'est ce morceau qui manquait peut-être :
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemBuilder: (context, index) {
                    final item = allShopItems[index];
                    return _buildShopItem(
                      context, 
                      db, 
                      item.id, 
                      item.name, 
                      item.description, 
                      item.price, 
                      item.icon, 
                      item.color
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET POUR UNE CARTE D'OBJET
  Widget _buildShopItem(BuildContext context, HabitDatabase db, String itemId, String name, String desc, int price, IconData icon, Color color) {
    bool isOwned = db.inventory.contains(itemId);
    bool isEquipped = db.itemActive == itemId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isEquipped ? Border.all(color: Colors.deepPurple, width: 3) : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 11), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 15),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isEquipped ? Colors.green : (isOwned ? Colors.deepPurple[100] : Colors.grey[100]),
              foregroundColor: isEquipped ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () {
              if (isEquipped) return; 

              if (isOwned) {
                db.setItemActive(itemId);
              } else {
                bool success = db.buyItem(itemId, price);
                if (success) {
                // 1. Son de succès
                SoundManager.play('coin.mp3');
                
                // 2. Message vert
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Achat réussi ! 🎉"),
                    backgroundColor: Colors.green,
                    duration: Duration(milliseconds: 800),
                  ),
                );
              } else {
                // 1. Message rouge (Pas de son ou son d'erreur)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Pas assez d'argent... 😭"),
                    backgroundColor: Colors.red,
                    duration: Duration(milliseconds: 800),
                  ),
                );
              }
              }
            },
            child: Text(
              isEquipped ? "Activé" : (isOwned ? "Équiper" : "$price 🪙"),
              style: const TextStyle(fontSize: 12),
            ),
          )
        ],
      ),
    );
  }
}