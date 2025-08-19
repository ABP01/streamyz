import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/network_manager.dart';
import '../utils/permission_manager.dart';
import 'zego_live_page.dart';

class StartLiveScreen extends StatefulWidget {
  const StartLiveScreen({super.key});

  @override
  State<StartLiveScreen> createState() => _StartLiveScreenState();
}

class _StartLiveScreenState extends State<StartLiveScreen> {
  final _descController = TextEditingController();
  bool _isLoading = false;
  final NetworkManager _networkManager = NetworkManager();

  Future<void> _startLive() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter une description')),
      );
      return;
    }

    // Vérifier la connectivité réseau
    if (!_networkManager.isOperational) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pas de connexion réseau. Vérifiez votre connexion Internet.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier les permissions
    final hasPermissions = await PermissionManager.hasEssentialPermissions();
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissions requises non accordées. Vérifiez les permissions caméra et microphone.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
        return;
      }

      // Utiliser le NetworkManager pour les opérations Firestore
      final liveID = await _networkManager.executeWithRetry(() async {
        return FirebaseFirestore.instance.collection('lives').doc().id;
      });

      // Récupérer les informations de l'utilisateur
      final userDoc = await _networkManager.executeWithRetry(() async {
        return await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
      });

      final userName = userDoc.data()?['username'] ?? 'Utilisateur';

      // Créer le document du live
      await _networkManager.executeWithRetry(() async {
        await FirebaseFirestore.instance.collection('lives').doc(liveID).set({
          'live_id': liveID,
          'id_host': user.uid,
          'name_host': userName,
          'desc': _descController.text.trim(),
          'is_live': true,
          'livestarttime': DateTime.now().millisecondsSinceEpoch,
          'liveendtime': 0,
          'stats': {'account': 0, 'likes': 0},
        });
      });

      if (mounted) {
        // Naviguer vers la page du live
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ZegoLivePage(
              liveID: liveID,
              userID: user.uid,
              userName: userName,
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Démarrer un live'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description du live',
                hintText: 'Donnez un titre à votre live...',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 24),

            // Indicateur de connectivité
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _networkManager.isOperational
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _networkManager.isOperational
                      ? Colors.green
                      : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _networkManager.isOperational ? Icons.wifi : Icons.wifi_off,
                    color: _networkManager.isOperational
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _networkManager.isOperational
                          ? 'Connecté et prêt à démarrer'
                          : 'Pas de connexion réseau',
                      style: TextStyle(
                        color: _networkManager.isOperational
                            ? Colors.green
                            : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: (_isLoading || !_networkManager.isOperational)
                  ? null
                  : _startLive,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('DÉMARRER LE LIVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }
}
