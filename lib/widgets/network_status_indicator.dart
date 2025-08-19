import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/network_manager.dart';

class NetworkStatusIndicator extends StatefulWidget {
  const NetworkStatusIndicator({super.key});

  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator> {
  final NetworkManager _networkManager = NetworkManager();
  bool _isConnected = true;
  bool _isFirestoreAvailable = true;

  @override
  void initState() {
    super.initState();
    _updateStatus();
    // Mettre à jour le statut toutes les 5 secondes
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _updateStatus();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateStatus() {
    setState(() {
      _isConnected = _networkManager.isConnected;
      _isFirestoreAvailable = _networkManager.isFirestoreAvailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected && _isFirestoreAvailable) {
      return const SizedBox.shrink(); // Masquer si tout va bien
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _getStatusMessage(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (!_isConnected) return Colors.red;
    if (!_isFirestoreAvailable) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (!_isConnected) return Icons.wifi_off;
    if (!_isFirestoreAvailable) return Icons.cloud_off;
    return Icons.check_circle;
  }

  String _getStatusMessage() {
    if (!_isConnected) return 'Pas de connexion Internet';
    if (!_isFirestoreAvailable) return 'Services temporairement indisponibles';
    return 'Connecté';
  }
}
