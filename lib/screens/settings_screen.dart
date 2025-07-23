import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showFollowers = true;
  bool _isDarkMode = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _showFollowers = (data != null && data.containsKey('showFollowers'))
              ? data['showFollowers'] as bool
              : true;
        });
      }
    }
  }

  Future<void> _updateShowFollowers(bool value) async {
    setState(() => _showFollowers = value);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'showFollowers': value},
      );
    }
  }

  void _toggleTheme(bool value) {
    setState(() => _isDarkMode = value);
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Mode sombre activé' : 'Mode clair activé'),
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _loading = true);
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Déconnecté')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Autoriser les autres à voir mes followers'),
            value: _showFollowers,
            onChanged: (val) => _updateShowFollowers(val),
          ),
          SwitchListTile(
            title: const Text('Mode sombre'),
            value: _isDarkMode,
            onChanged: (val) => _toggleTheme(val),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _loading ? null : _logout,
          ),
        ],
      ),
    );
  }
}
