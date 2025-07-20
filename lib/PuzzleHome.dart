import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:puzzle_collab/model/puzzle_pieces_model.dart';
import 'package:puzzle_collab/services/signalr_service.dart';
import 'package:puzzle_collab/PuzzleGrid.dart'; // Assicurati di usare la versione moderna del PuzzleGrid suggerita prima

class PuzzleHome extends StatefulWidget {
  const PuzzleHome({super.key});

  @override
  State<PuzzleHome> createState() => _PuzzleHomeState();
}

class _PuzzleHomeState extends State<PuzzleHome> {
  ui.Image? _originalImage;
  List<PuzzlePieceModel> _pieces = [];
  static const int _gridSize = 10;

  late SignalRService _signalRService;
  String _connectionStatus = 'Disconnesso';
  List<User> _onlineUsers = [];
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoggedIn = false;
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _signalRService = SignalRService(
      'http://localhost/puzzlehub',
    ); // Nessuna porta qui, Nginx è sulla 80
    _signalRService.onPuzzleStateReceived = (newState) {
      setState(() {
        _pieces = newState.map((data) {
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
          piece.currentX = data['currentX'];
          piece.currentY = data['currentY'];
          piece.isPlacedCorrectly = data['isPlacedCorrectly'];
          return piece;
        }).toList();

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

    _signalRService.onError = (message) {
      setState(() {
        _connectionStatus = 'Errore: $message';
        _isLoggedIn = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('SignalR: $message')));
      debugPrint("SignalR Error from UI: $message");
    };

    _signalRService.onConnected = (message) {
      setState(() {
        _connectionStatus = message;
      });
      debugPrint("SignalR Connected Status from UI: $message");
      if (_myUsername != null && _myUsername!.isNotEmpty) {
        _signalRService.sendUsername(_myUsername!);
      }
    };

    _signalRService.onUserListReceived = (userList) {
      setState(() {
        _onlineUsers = userList;
      });
    };

    _loadImage();
  }

  @override
  void dispose() {
    _signalRService.disconnect();
    _usernameController.dispose();
    super.dispose();
  }

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
      if (_pieces.isEmpty) {
        _createAndShufflePuzzlePieces();
      }
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

  void _rearrangePieces() => _signalRService.sendShuffleRequest();
  void _resetPieces() => _signalRService.sendResetRequest();

  void _connectWithUsername() {
    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      _myUsername = username;
      _signalRService.connect();
      setState(() => _isLoggedIn = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per favore, inserisci un username.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text("Entra nel Puzzle")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Scegli il tuo Username',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _connectWithUsername(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _connectWithUsername,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text('Gioca', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20),
                Text(
                  _connectionStatus,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_originalImage == null || _pieces.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Utenti Online:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_onlineUsers.isEmpty)
                          const Text('Nessun utente online.'),
                        ..._onlineUsers
                            .map(
                              (user) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Text(
                                  user.username,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                _connectionStatus,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueGrey.shade50,
              Colors.blue.shade100.withOpacity(0.22),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_myUsername != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent.shade100,
                        child: Text(
                          _myUsername!.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _myUsername!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double size = min(
                    min(constraints.maxWidth, constraints.maxHeight),
                    420,
                  );
                  return Material(
                    elevation: 14,
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.blueGrey.withOpacity(0.13),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.withOpacity(0.11),
                            blurRadius: 28,
                            spreadRadius: 4,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.blueGrey.withOpacity(0.18),
                          width: 1.5,
                        ),
                      ),
                      child: PuzzleGrid(
                        originalImage: _originalImage!,
                        pieces: _pieces,
                        gridCount: _gridSize,
                        onPieceMoveRequested: (pieceId, targetX, targetY) {
                          _signalRService.sendMovePiece(
                            pieceId,
                            targetX,
                            targetY,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton.extended(
              heroTag: 'rearrangeButton',
              onPressed: _rearrangePieces,
              label: const Text('Mescola'),
              icon: const Icon(Icons.shuffle),
              backgroundColor: Colors.blueAccent.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 7,
            ),
            const SizedBox(width: 16),
            FloatingActionButton.extended(
              heroTag: 'resetButton',
              onPressed: _resetPieces,
              label: const Text('Reset'),
              icon: const Icon(Icons.refresh),
              backgroundColor: Colors.redAccent.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 7,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
