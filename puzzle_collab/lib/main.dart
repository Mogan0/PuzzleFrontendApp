import 'dart:math';

import 'package:flutter/material.dart';
import 'package:puzzle_collab/PuzzleGrid.dart';
import 'package:puzzle_collab/model/puzzle_pieces_model.dart';
import 'package:signalr_netcore/signalr_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late HubConnection hubConnection;
  String log = "";
  List<PuzzlePieceModel> puzzlePieces = [];

  @override
  void initState() {
    super.initState();

    final serverUrl = "http://localhost:5287/puzzlehub";
    hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();

    hubConnection.onclose(({error}) {
      setState(() => log += "\nDisconnesso!");
    });

    hubConnection.on("ReceiveMove", (arguments) {
      print("Flutter ha ricevuto ReceiveMove: $arguments");

      if (arguments != null && arguments.length >= 3) {
        int id = (int.parse(arguments[0].toString()));
        int x = (int.parse(arguments[1].toString()));
        int y = (int.parse(arguments[2].toString()));
        setState(() {
          final idx = puzzlePieces.indexWhere((p) => p.id == id);
          if (idx != -1) {
            puzzlePieces[idx].x = x;
            puzzlePieces[idx].y = y;
            log += "\nRicevuto move: pezzo $id spostato in ($x, $y)";
          }
        });
      }
    });

    hubConnection.on("InitPuzzle", (arguments) {
      print("Flutter ha inizializzato");
      if (arguments != null && arguments.isNotEmpty && arguments[0] != null) {
        var pieceList = List<Map<String, dynamic>>.from(
          (arguments[0] as List).map((item) => Map<String, dynamic>.from(item)),
        );

        setState(() {
          puzzlePieces = pieceList
              .map((pieceMap) => PuzzlePieceModel.fromMap(pieceMap))
              .toList();
          log += "\nInitPuzzle ricevuto: ${puzzlePieces.length} pezzi";
        });
      }
    });

    _connect();
  }

  Future<void> _connect() async {
    await hubConnection.start();
    setState(() {
      log += "\nConnesso!";
    });
  }

  Future<void> _sendMove() async {
    try {
      await hubConnection.invoke("MovePiece", args: [1, 5, 5]);
      setState(() {
        log += "\nInviato move: pezzo 1 a (5, 5)";
      });
    } catch (e) {
      setState(() {
        log += "\nERRORE invio move: $e";
      });
    }
  }

  @override
  void dispose() {
    hubConnection.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Puzzle Real-time')),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () => _sendMove(),
              child: const Text('Mossa random'),
            ),
            Center(child: PuzzleGrid(pieces: puzzlePieces)),
          ],
        ),
      ),
    );
  }
}
