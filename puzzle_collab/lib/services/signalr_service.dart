import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/material.dart'; // Per debugPrint

class User {
  final String connectionId;
  final String username;

  User({required this.connectionId, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(connectionId: json['connectionId'], username: json['username']);
  }
}

class SignalRService {
  final String _hubUrl;
  HubConnection? _hubConnection;

  Function(List<Map<String, dynamic>>)? onPuzzleStateReceived;
  Function(String)? onError;
  Function(String)? onConnected;
  Function(List<User>)? onUserListReceived;

  SignalRService(this._hubUrl);

  Future<void> connect() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(_hubUrl)
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000])
        .build();

    _hubConnection?.onclose(({Exception? error}) {
      debugPrint("Connessione SignalR chiusa: $error");
      onError?.call(
        "Connessione chiusa: ${error?.toString() ?? 'unknown error'}",
      );
    });

    _hubConnection?.onreconnected(({String? connectionId}) {
      debugPrint("Connessione SignalR riconnessa: $connectionId");
      onConnected?.call("Riconnesso: $connectionId");
    });

    _hubConnection?.onreconnecting(({Exception? error}) {
      debugPrint("Riconnessione SignalR in corso: $error");
      onError?.call(
        "Riconnessione in corso: ${error?.toString() ?? 'unknown error'}",
      );
    });

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

    _hubConnection?.on("ReceiveUserList", ([arguments]) {
      if (arguments != null && arguments.isNotEmpty) {
        List<User> userList = (arguments[0] as List)
            .cast<Map<String, dynamic>>()
            .map((json) => User.fromJson(json))
            .toList();
        onUserListReceived?.call(userList);
        debugPrint(
          "Lista utenti ricevuta: ${userList.map((u) => u.username).join(', ')}",
        );
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

  Future<void> sendUsername(String username) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.invoke("SetUsername", args: [username]);
        debugPrint("Inviato username: $username");
      } catch (e) {
        debugPrint("Errore durante l'invio dell'username: $e");
        onError?.call("Errore nell'invio dell'username: $e");
      }
    } else {
      debugPrint("Non connesso al server per inviare l'username.");
      onError?.call("Non connesso al server.");
    }
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
