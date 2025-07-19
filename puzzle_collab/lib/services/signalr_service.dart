// lib/services/signalr_service.dart

import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/material.dart'; // Per debugPrint
import 'package:logging/logging.dart';

class SignalRService {
  final String _hubUrl;
  HubConnection? _hubConnection;

  Function(List<Map<String, dynamic>>)? onPuzzleStateReceived;
  Function(String)? onError;
  Function(String)? onConnected;

  SignalRService(this._hubUrl);

  Future<void> connect() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(_hubUrl)
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000])
        .build();

    _hubConnection?.onclose(({Exception? error}) {
      // Corretto precedentemente
      debugPrint("Connessione SignalR chiusa: $error");
      onError?.call(
        "Connessione chiusa: ${error?.toString() ?? 'unknown error'}",
      );
    });

    // --- CORREZIONE QUI: onreconnected si aspetta un parametro nominato 'connectionId' ---
    _hubConnection?.onreconnected(({String? connectionId}) {
      // <-- NOTA le parentesi graffe qui!
      debugPrint("Connessione SignalR riconnessa: $connectionId");
      onConnected?.call("Riconnesso: $connectionId");
    });

    // --- CORREZIONE QUI: onreconnecting si aspetta un parametro nominato 'error' ---
    _hubConnection?.onreconnecting(({Exception? error}) {
      // <-- NOTA le parentesi graffe qui!
      debugPrint("Riconnessione SignalR in corso: $error");
      onError?.call(
        "Riconnessione in corso: ${error?.toString() ?? 'unknown error'}",
      );
    });

    // Questo è già corretto
    _hubConnection?.on("ReceivePuzzleState", ([arguments]) {
      if (arguments != null && arguments.isNotEmpty) {
        List<Map<String, dynamic>> newState;
        if (arguments[0] is List) {
          newState = (arguments[0] as List).cast<Map<String, dynamic>>();
        } else {
          newState = (arguments as List).cast<Map<String, dynamic>>();
        }
        onPuzzleStateReceived?.call(newState);
        debugPrint("Stato puzzle ricevuto: $newState");
      }
    });

    try {
      await _hubConnection?.start();
      debugPrint("Connessione SignalR avviata con successo!");
      onConnected?.call("Connesso al server!");
    } catch (e) {
      debugPrint("Errore durante l'avvio della connessione SignalR: $e");
      onError?.call("Errore di connessione: $e");
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    debugPrint("Connessione SignalR interrotta.");
  }

  Future<void> sendMovePiece(int pieceId, int targetX, int targetY) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.invoke(
          "MovePiece",
          args: [pieceId, targetX, targetY],
        );
        debugPrint("Inviato MovePiece: ID $pieceId a ($targetX, $targetY)");
      } catch (e) {
        debugPrint("Errore durante l'invio di MovePiece: $e");
        onError?.call("Errore nell'invio del movimento: $e");
      }
    } else {
      debugPrint("Non connesso al server per inviare MovePiece.");
      onError?.call("Non connesso al server.");
    }
  }

  Future<void> sendShuffleRequest() async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.invoke("ShufflePuzzle");
        debugPrint("Inviata richiesta di mescolare al server.");
      } catch (e) {
        debugPrint("Errore durante l'invio di ShufflePuzzle: $e");
        onError?.call("Errore nell'invio della richiesta di mescolare: $e");
      }
    } else {
      debugPrint("Non connesso al server per inviare ShufflePuzzle.");
      onError?.call("Non connesso al server.");
    }
  }

  Future<void> sendResetRequest() async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.invoke("ResetPuzzle");
        debugPrint("Inviata richiesta di reset al server.");
      } catch (e) {
        debugPrint("Errore durante l'invio di ResetPuzzle: $e");
        onError?.call("Errore nell'invio della richiesta di reset: $e");
      }
    } else {
      debugPrint("Non connesso al server per inviare ResetPuzzle.");
      onError?.call("Non connesso al server.");
    }
  }
}
