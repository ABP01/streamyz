import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../utils/permission_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Paramètres essentiels
  bool _isDarkMode = false;
  String _language = 'Français';
  bool _profileVisible = true;
  bool _allowDirectMessages = true;
  bool _notificationsEnabled = true;
  bool _liveNotifications = true;

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
        final data = doc.data() ?? {};
        setState(() {
          _language = data['language'] ?? 'Français';
          _profileVisible = data['profileVisible'] ?? true;
          _allowDirectMessages = data['allowDirectMessages'] ?? true;
          _notificationsEnabled = data['notificationsEnabled'] ?? true;
          _liveNotifications = data['liveNotifications'] ?? true;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'language': _language,
            'profileVisible': _profileVisible,
            'allowDirectMessages': _allowDirectMessages,
            'notificationsEnabled': _notificationsEnabled,
            'liveNotifications': _liveNotifications,
          });
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Déconnecté avec succès')));
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Supprimer les données Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
          // Supprimer le compte Auth
          await user.delete();
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Compte supprimé')));
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await _saveSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paramètres sauvegardés')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Apparence
                _buildSectionHeader('Apparence', Icons.palette),
                _buildSettingsCard([
                  SwitchListTile(
                    title: const Text('Mode sombre'),
                    subtitle: const Text('Interface sombre pour vos yeux'),
                    value: _isDarkMode,
                    onChanged: _toggleTheme,
                    secondary: const Icon(Icons.dark_mode),
                  ),
                  ListTile(
                    title: const Text('Langue'),
                    subtitle: Text(_language),
                    leading: const Icon(Icons.language),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(),
                  ),
                ]),

                const SizedBox(height: 20),

                // Section Confidentialité
                _buildSectionHeader('Confidentialité', Icons.privacy_tip),
                _buildSettingsCard([
                  SwitchListTile(
                    title: const Text('Profil visible'),
                    subtitle: const Text(
                      'Autres utilisateurs peuvent voir votre profil',
                    ),
                    value: _profileVisible,
                    onChanged: (val) => setState(() => _profileVisible = val),
                    secondary: const Icon(Icons.visibility),
                  ),
                  SwitchListTile(
                    title: const Text('Messages directs'),
                    subtitle: const Text('Autoriser les messages privés'),
                    value: _allowDirectMessages,
                    onChanged: (val) =>
                        setState(() => _allowDirectMessages = val),
                    secondary: const Icon(Icons.message),
                  ),
                ]),

                const SizedBox(height: 20),

                // Section Notifications
                _buildSectionHeader('Notifications', Icons.notifications),
                _buildSettingsCard([
                  SwitchListTile(
                    title: const Text('Notifications activées'),
                    subtitle: const Text('Recevoir toutes les notifications'),
                    value: _notificationsEnabled,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                    secondary: const Icon(Icons.notifications_active),
                  ),
                  SwitchListTile(
                    title: const Text('Nouveaux lives'),
                    subtitle: const Text(
                      'Quand quelqu\'un que vous suivez démarre',
                    ),
                    value: _liveNotifications,
                    onChanged: _notificationsEnabled
                        ? (val) => setState(() => _liveNotifications = val)
                        : null,
                    secondary: const Icon(Icons.live_tv),
                  ),
                ]),

                const SizedBox(height: 20),

                // Section Permissions
                _buildSectionHeader('Permissions', Icons.security),
                _buildSettingsCard([
                  ListTile(
                    title: const Text('État des permissions'),
                    subtitle: const Text('Vérifier et gérer les autorisations'),
                    leading: const Icon(Icons.verified_user),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPermissionsDialog(),
                  ),
                  ListTile(
                    title: const Text('Ouvrir les paramètres'),
                    subtitle: const Text(
                      'Modifier les permissions dans les paramètres système',
                    ),
                    leading: const Icon(Icons.settings),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => PermissionManager.openSystemSettings(),
                  ),
                ]),

                const SizedBox(height: 20),

                // Section Sécurité
                _buildSectionHeader('Sécurité', Icons.lock),
                _buildSettingsCard([
                  ListTile(
                    title: const Text('Changer le mot de passe'),
                    subtitle: const Text('Modifier votre mot de passe'),
                    leading: const Icon(Icons.key),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(),
                  ),
                ]),

                const SizedBox(height: 20),

                // Section Compte
                _buildSectionHeader('Compte', Icons.account_circle),
                _buildSettingsCard([
                  ListTile(
                    title: const Text('Support client'),
                    subtitle: const Text('Contactez-nous pour de l\'aide'),
                    leading: const Icon(Icons.help_outline),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSupportDialog(),
                  ),
                  ListTile(
                    title: const Text('À propos'),
                    subtitle: const Text('Version 1.0.0'),
                    leading: const Icon(Icons.info_outline),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutDialog(),
                  ),
                ]),

                const SizedBox(height: 20),

                // Section Danger
                _buildSectionHeader(
                  'Zone de danger',
                  Icons.warning,
                  Colors.red,
                ),
                _buildSettingsCard([
                  ListTile(
                    title: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: Colors.orange),
                    ),
                    subtitle: const Text('Déconnexion de votre compte'),
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _logout,
                  ),
                  ListTile(
                    title: const Text(
                      'Supprimer le compte',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Action irréversible'),
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _deleteAccount,
                  ),
                ]),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color ?? Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: children
            .map(
              (child) => child is ListTile || child is SwitchListTile
                  ? child
                  : Padding(padding: const EdgeInsets.all(8), child: child),
            )
            .toList(),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'Français',
              groupValue: _language,
              onChanged: (val) {
                setState(() => _language = val!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (val) {
                setState(() => _language = val!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: 'Nouveau mot de passe',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(
                  passwordController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe modifié')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors de la modification'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support client'),
        content: const Text(
          'Pour toute question ou problème, contactez-nous à :\n\nsupport@streamyz.app\n\nNous répondons généralement sous 24h.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: 'support@streamyz.app'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email copié dans le presse-papier'),
                ),
              );
            },
            child: const Text('Copier email'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de Streamyz'),
        content: const Text(
          'Streamyz v1.0.0\n\nUne application de streaming social moderne et intuitive.\n\nDéveloppé avec ❤️ par l\'équipe Streamyz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog() async {
    try {
      // Obtenir le résumé des permissions
      final summary = await PermissionManager.getPermissionsSummary();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.blue),
              SizedBox(width: 8),
              Text('État des Permissions'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Permissions nécessaires pour Streamyz:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildPermissionStatus(
                  '🎤 Microphone',
                  summary['microphone'] == true,
                  'Requis pour les lives audio',
                ),
                const SizedBox(height: 8),

                _buildPermissionStatus(
                  '📷 Caméra',
                  summary['camera'] == true,
                  'Requis pour les lives vidéo',
                ),
                const SizedBox(height: 8),

                _buildPermissionStatus(
                  '💾 Stockage',
                  summary['storage'] == true,
                  'Pour sauvegarder les enregistrements',
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: summary['hasEssential'] == true
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: summary['hasEssential'] == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        summary['hasEssential'] == true
                            ? Icons.check_circle
                            : Icons.warning,
                        color: summary['hasEssential'] == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          summary['hasEssential'] == true
                              ? 'Toutes les permissions essentielles sont accordées !'
                              : 'Certaines permissions manquent. L\'app fonctionnera en mode dégradé.',
                          style: TextStyle(
                            color: summary['hasEssential'] == true
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (summary['hasEssential'] != true) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '💡 Astuce: Vous pouvez accorder les permissions dans les paramètres système pour profiter de toutes les fonctionnalités.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (summary['hasEssential'] != true)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  PermissionManager.openSystemSettings();
                },
                child: const Text('Paramètres'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la vérification des permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPermissionStatus(
    String title,
    bool isGranted,
    String description,
  ) {
    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle : Icons.cancel,
          color: isGranted ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Text(
          isGranted ? 'Accordée' : 'Refusée',
          style: TextStyle(
            fontSize: 12,
            color: isGranted ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
