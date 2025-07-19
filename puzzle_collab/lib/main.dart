import 'dart:math'; // Per min e random
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Per ui.Image e decodeImageFromList
import 'package:flutter/services.dart' show rootBundle;
import 'package:puzzle_collab/PuzzleHome.dart'; // Per rootBundle

// Modello base per un pezzo del puzzle
class PuzzlePieceModel {
  final int id;
  int currentX; // Posizione attuale X della tessera nella griglia
  int currentY; // Posizione attuale Y della tessera nella griglia
  final int correctX; // Posizione X corretta nella griglia (origine)
  final int correctY; // Posizione Y corretta nella griglia (origine)

  PuzzlePieceModel({
    required this.id,
    required this.currentX,
    required this.currentY,
    required this.correctX,
    required this.correctY,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Puzzle 10x10 DEMO")),
        body: const PuzzleHome(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
