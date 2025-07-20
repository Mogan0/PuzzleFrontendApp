import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:puzzle_collab/PuzzleHome.dart';

class PuzzlePieceModel {
  final int id;
  int currentX;
  int currentY;
  final int correctX;
  final int correctY;

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
      title: 'Puzzle 10x10 DEMO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            letterSpacing: 1.5,
          ),
        ),
        useMaterial3: true,
      ),
      home: const PuzzleHomeScaffold(),
    );
  }
}

class PuzzleHomeScaffold extends StatelessWidget {
  const PuzzleHomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Stack(
          children: [
            Container(
              height: 74,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.16),
                    Colors.blueGrey.withOpacity(0.12),
                    Colors.white.withOpacity(0.93),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.extension_rounded,
                    color: Colors.blueAccent.shade400,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Puzzle 10x10 DEMO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1.1,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              toolbarHeight: 74,
            ),
          ],
        ),
      ),
      body: const PuzzleHome(),
    );
  }
}
