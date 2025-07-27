import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'zego_live_page.dart';

class StartLiveScreen extends StatefulWidget {
  const StartLiveScreen({super.key});

  @override
  State<StartLiveScreen> createState() => _StartLiveScreenState();
}

class _StartLiveScreenState extends State<StartLiveScreen> {
  final _descController = TextEditingController();
  bool _isLoading = false;

  Future<void> _startLive() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter une description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Générer un ID unique pour le live
      final liveID = FirebaseFirestore.instance.collection('lives').doc().id;

      // Récupérer les informations de l'utilisateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userName = userDoc.data()?['username'] ?? 'Utilisateur';

      // Créer le document du live
      await FirebaseFirestore.instance.collection('lives').doc(liveID).set({
        'live_id': liveID,
        'id_host': user.uid,
        'name_host': userName,
        'desc': _descController.text.trim(),
        'is_live': true,
        'livestarttime': DateTime.now().millisecondsSinceEpoch,
        'liveendtime': 0,
        'has_recording': false,
        'recording_url': '',
        'is_recording': false,
        'stats': {'account': 0, 'likes': 0},
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
            ElevatedButton(
              onPressed: _isLoading ? null : _startLive,
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
