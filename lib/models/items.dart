import 'package:flutter/material.dart';

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;
  final String type; // 'skin' ou 'consumable'

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
    required this.type,
  });
}

// NOTRE CATALOGUE OFFICIEL
final List<ShopItem> allShopItems = [
  ShopItem(
    id: 'potion',
    name: 'Potion de Soin',
    description: 'Répare un jour raté (À venir)',
    price: 50,
    icon: Icons.local_drink,
    color: Colors.redAccent,
    type: 'consumable',
  ),
  ShopItem(
    id: 'skin_dragon',
    name: 'Skin Dragon',
    description: 'Transforme votre compagnon',
    price: 100,
    icon: Icons.pets,
    color: Colors.purpleAccent,
    type: 'skin',
  ),
  ShopItem(
    id: 'skin_robot',
    name: 'Skin Robot',
    description: 'Mode Futuriste',
    price: 200,
    icon: Icons.smart_toy,
    color: Colors.blueAccent,
    type: 'skin',
  ),
];