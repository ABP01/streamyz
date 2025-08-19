import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  bool _isConnected = true;
  bool _isFirestoreAvailable = true;
  Timer? _connectivityTimer;
  final Connectivity _connectivity = Connectivity();

  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      _handleConnectivityChange(result);
    });
    await _checkConnectivity();
    _startPeriodicCheck();
    debugPrint('🌐 NetworkManager initialisé');
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    if (wasConnected != _isConnected) {
      debugPrint(
        '🌐 Connectivité: ${_isConnected ? 'Connecté' : 'Déconnecté'}',
      );
      _checkFirestoreAvailability();
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result != ConnectivityResult.none;
    } catch (e) {
      _isConnected = false;
    }
  }

  Future<void> _checkFirestoreAvailability() async {
    if (!_isConnected) {
      _isFirestoreAvailable = false;
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('_health_check')
          .doc('test')
          .get(const GetOptions(source: Source.server));
      _isFirestoreAvailable = true;
    } catch (e) {
      _isFirestoreAvailable = false;
    }
  }

  void _startPeriodicCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnectivity();
      if (_isConnected) {
        _checkFirestoreAvailability();
      }
    });
  }

  bool get isConnected => _isConnected;
  bool get isFirestoreAvailable => _isFirestoreAvailable;
  bool get isOperational => _isConnected && _isFirestoreAvailable;

  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        if (!_isConnected) throw Exception('Pas de connexion réseau');
        if (!_isFirestoreAvailable) throw Exception('Firestore indisponible');
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(delay * attempts);
        await _checkConnectivity();
        await _checkFirestoreAvailability();
      }
    }
    throw Exception('Nombre maximum de tentatives atteint');
  }

  void dispose() {
    _connectivityTimer?.cancel();
  }
}
