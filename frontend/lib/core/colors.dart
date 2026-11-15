import 'package:flutter/material.dart';


const colorNames = [
  'BLACK', 'BLUE', 'BROWN', 'GRAY', 'GREEN', 'ORANGE',
  'PINK', 'PURPLE', 'RED', 'WHITE', 'YELLOW',
];

Color colorFromName(String? name) {
  switch (name) {
    case 'BLACK': return Colors.black;
    case 'BLUE': return Colors.blue;
    case 'BROWN': return Colors.brown;
    case 'GRAY': return Colors.grey;
    case 'GREEN': return Colors.green;
    case 'ORANGE': return Colors.orange;
    case 'PINK': return Colors.pink;
    case 'PURPLE': return Colors.purple;
    case 'RED': return Colors.red;
    case 'WHITE': return Colors.white;
    case 'YELLOW': return Colors.yellow;
    default: return Colors.grey.shade400;
  }
}