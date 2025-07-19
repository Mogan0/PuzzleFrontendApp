import 'dart:math';
import 'dart:ui' as ui;

import 'package:puzzle_collab/PuzzleGrid.dart';
import 'package:puzzle_collab/model/puzzle_pieces_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:puzzle_collab/services/signalr_service.dart'; // <--- NUOVA IMPORTAZIONE

// ... (PuzzlePieceModel, MyApp e gli altri helper rimangono invariati) ...
// Per semplicità, ipotizzo che PuzzlePieceModel sia ancora nello stesso file,
// altrimenti assicurati che il suo import sia corretto.

class PuzzleHome extends StatefulWidget {
  const PuzzleHome({super.key});

  @override
  State<PuzzleHome> createState() => _PuzzleHomeState();
}

class _PuzzleHomeState extends State<PuzzleHome> {
  ui.Image? _originalImage;
  List<PuzzlePieceModel> _pieces = [];
  static const int _gridSize = 10;

  // --- ISTANZA DEL SERVIZIO SIGNALR ---
  late SignalRService _signalRService;
  // Variabile per mostrare lo stato della connessione nella UI
  String _connectionStatus = 'Disconnesso';

  @override
  void initState() {
    super.initState();

    // Inizializza il servizio SignalR con l'URL corretto del tuo backend.
    // ***** RICORDA DI AGGIORNARE QUESTO URL *****
    _signalRService = SignalRService(
      'http://localhost:5000/puzzlehub',
    ); // <--- USA LOCALHOST QUI

    // --- REGISTRAZIONE DEI LISTENER DAL SERVIZIO SIGNALR ---
    // Questa funzione viene chiamata quando il server invia un nuovo stato del puzzle.
    _signalRService.onPuzzleStateReceived = (newState) {
      setState(() {
        // Aggiorna la lista _pieces con i dati ricevuti dal server.
        // È fondamentale mappare i dati ricevuti (Map<String, dynamic>)
        // ai tuoi oggetti PuzzlePieceModel esistenti o crearne di nuovi.
        _pieces = newState.map((data) {
          // Cerca il pezzo esistente per ID, o crea una nuova istanza se non esiste (utile per robustezza)
          final piece = _pieces.firstWhere(
            (p) => p.id == data['id'],
            orElse: () => PuzzlePieceModel(
              id: data['id'],
              currentX: data['currentX'],
              currentY: data['currentY'],
              correctX: data['correctX'],
              correctY: data['correctY'],
              isPlacedCorrectly: data['isPlacedCorrectly'],
            ),
          );
          // Aggiorna le proprietà del pezzo esistente con i nuovi valori dal server
          piece.currentX = data['currentX'];
          piece.currentY = data['currentY'];
          piece.isPlacedCorrectly = data['isPlacedCorrectly'];
          return piece;
        }).toList();

        // Nascondi eventuali snackbar precedenti (es. "Puzzle Completato!")
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Controlla la condizione di vittoria SOLO DOPO aver ricevuto e applicato
        // lo stato aggiornato dal server.
        bool allCorrect = _pieces.every(
          (p) => p.currentX == p.correctX && p.currentY == p.correctY,
        );

        if (allCorrect) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Complimenti! Puzzle Completato!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    };

    // Listener per gli errori di connessione
    _signalRService.onError = (message) {
      setState(() {
        _connectionStatus = 'Errore: $message';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('SignalR: $message')));
    };

    // Listener per lo stato di connessione (connesso/riconnesso)
    _signalRService.onConnected = (message) {
      setState(() {
        _connectionStatus = message;
      });
    };

    // Avvia il caricamento dell'immagine e la connessione SignalR in parallelo
    _loadImage();
    _signalRService.connect();
  }

  @override
  void dispose() {
    _signalRService
        .disconnect(); // Disconnetti da SignalR quando il widget viene eliminato
    super.dispose();
  }

  // --- Funzioni di Caricamento e Creazione Pezzi ---
  // Queste rimangono simili, ma la mescolatura iniziale potrebbe essere sostituita
  // dallo stato iniziale inviato dal server dopo la connessione.
  Future<void> _loadImage() async {
    final ByteData data = await rootBundle.load(
      'assets/Ginger_european_cat.jpg',
    );
    final List<int> bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(
      Uint8List.fromList(bytes),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    setState(() {
      _originalImage = frameInfo.image;
      // In un contesto multiplayer, potresti voler attendere lo stato iniziale dal server
      // prima di inizializzare i pezzi, o usare questo come fallback.
      // Per ora, lo manteniamo per avere un puzzle giocabile anche senza connessione immediata.
      _createAndShufflePuzzlePieces();
    });
  }

  void _createAndShufflePuzzlePieces() {
    if (_originalImage == null) return;

    List<PuzzlePieceModel> tempPieces = [];
    List<Offset> shuffledPositions = [];

    for (int i = 0; i < _gridSize * _gridSize; i++) {
      int correctX = i % _gridSize;
      int correctY = i ~/ _gridSize;

      tempPieces.add(
        PuzzlePieceModel(
          id: i,
          currentX: correctX,
          currentY: correctY,
          correctX: correctX,
          correctY: correctY,
          isPlacedCorrectly: false,
        ),
      );
      shuffledPositions.add(Offset(correctX.toDouble(), correctY.toDouble()));
    }

    shuffledPositions.shuffle(Random());

    setState(() {
      for (int i = 0; i < tempPieces.length; i++) {
        tempPieces[i].currentX = shuffledPositions[i].dx.toInt();
        tempPieces[i].currentY = shuffledPositions[i].dy.toInt();
        tempPieces[i].isPlacedCorrectly = false;
      }
      _pieces = tempPieces;
    });
  }

  // --- Funzioni per i Pulsanti: Ora Invocano il Servizio SignalR ---
  void _rearrangePieces() {
    _signalRService.sendShuffleRequest();
    // Non aggiornare _pieces qui! L'aggiornamento avverrà tramite la callback
    // onPuzzleStateReceived quando il server invierà il nuovo stato.
  }

  void _resetPieces() {
    _signalRService.sendResetRequest();
    // Anche qui, non aggiornare _pieces direttamente.
  }

  @override
  Widget build(BuildContext context) {
    // Mostra un indicatore di caricamento e lo stato della connessione se l'immagine non è pronta
    if (_originalImage == null || _pieces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _connectionStatus,
            ), // Mostra lo stato attuale della connessione
          ],
        ),
      );
    }

    return Builder(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Puzzle Multiplayer DEMO"),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    _connectionStatus,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
          body: PuzzleGrid(
            originalImage: _originalImage!,
            pieces: _pieces,
            gridCount: _gridSize,
            // --- PASSA LA CALLBACK AL PUZZLEGRID ---
            // Quando un pezzo viene trascinato e rilasciato, PuzzleGrid chiamerà questa funzione.
            // Questa funzione a sua volta invierà la richiesta al server SignalR.
            onPieceMoveRequested: (pieceId, targetX, targetY) {
              _signalRService.sendMovePiece(pieceId, targetX, targetY);
              // NON chiamare setState qui. L'UI si aggiornerà solo quando
              // il server invierà il nuovo stato tramite 'ReceivePuzzleState'.
            },
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'rearrangeButton',
                onPressed: _rearrangePieces,
                label: const Text('Mescola'),
                icon: const Icon(Icons.shuffle),
                backgroundColor: Colors.blueAccent,
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'resetButton',
                onPressed: _resetPieces,
                label: const Text('Reset'),
                icon: const Icon(Icons.refresh),
                backgroundColor: Colors.redAccent,
              ),
              FloatingActionButton.extended(
                onPressed: () async {
                  debugPrint("Tentativo manuale di connessione...");
                  await _signalRService.connect();
                  debugPrint("Richiesta di connessione completata.");
                },
                label: const Text('Connetti Man.'),
                icon: const Icon(Icons.link),
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}
