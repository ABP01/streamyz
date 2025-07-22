import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showFollowers = true;
  bool _isDarkMode = false;

  void _logout() {
    // TODO: Implémenter la logique de déconnexion réelle
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Afficher un message ou rediriger vers la page de login
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Déconnecté')),
    );
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
            onChanged: (val) {
              setState(() => _showFollowers = val);
            },
          ),
          SwitchListTile(
            title: const Text('Mode sombre'),
            value: _isDarkMode,
            onChanged: (val) {
              setState(() => _isDarkMode = val);
              // Pour un vrai mode dark, il faudrait utiliser un provider ou setState global
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
// ...existing code...
