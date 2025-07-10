import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveSettingsPage extends StatefulWidget {
  const LiveSettingsPage({super.key});

  @override
  State<LiveSettingsPage> createState() => _LiveSettingsPageState();
}

class _LiveSettingsPageState extends State<LiveSettingsPage> {
  bool _allowGifts = true;
  bool _allowComments = true;
  bool _notifyFollowers = true;
  bool _recordLive = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final liveSettings =
            data['liveSettings'] as Map<String, dynamic>? ?? {};

        setState(() {
          _allowGifts = liveSettings['allowGifts'] ?? true;
          _allowComments = liveSettings['allowComments'] ?? true;
          _notifyFollowers = liveSettings['notifyFollowers'] ?? true;
          _recordLive = liveSettings['recordLive'] ?? false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'liveSettings': {
            'allowGifts': _allowGifts,
            'allowComments': _allowComments,
            'notifyFollowers': _notifyFollowers,
            'recordLive': _recordLive,
          },
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres sauvegardés !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres Live'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Interactions'),

          _buildSettingsTile(
            title: 'Autoriser les cadeaux',
            subtitle: 'Les spectateurs peuvent envoyer des cadeaux virtuels',
            value: _allowGifts,
            onChanged: (value) => setState(() => _allowGifts = value),
            icon: Icons.card_giftcard,
            iconColor: Colors.orange,
          ),

          _buildSettingsTile(
            title: 'Autoriser les commentaires',
            subtitle: 'Les spectateurs peuvent commenter en direct',
            value: _allowComments,
            onChanged: (value) => setState(() => _allowComments = value),
            icon: Icons.chat_bubble,
            iconColor: Colors.blue,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),

          _buildSettingsTile(
            title: 'Notifier mes abonnés',
            subtitle: 'Informer automatiquement quand je démarre un live',
            value: _notifyFollowers,
            onChanged: (value) => setState(() => _notifyFollowers = value),
            icon: Icons.notifications,
            iconColor: Colors.green,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Enregistrement'),

          _buildSettingsTile(
            title: 'Enregistrer le live',
            subtitle:
                'Sauvegarder automatiquement mes lives (bientôt disponible)',
            value: _recordLive,
            onChanged: null, // Désactivé pour l'instant
            icon: Icons.videocam,
            iconColor: Colors.red,
          ),

          const SizedBox(height: 32),

          // Statistiques du compte
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes statistiques',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticsItem(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Conseils pour un bon live
          Card(
            color: Colors.blue.shade50,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Conseils pour un live réussi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('📱 Vérifiez votre connexion internet'),
                  _buildTip('💡 Assurez-vous d\'avoir un bon éclairage'),
                  _buildTip('🎤 Testez votre audio avant de commencer'),
                  _buildTip('👥 Interagissez avec vos spectateurs'),
                  _buildTip('🎯 Préparez votre contenu à l\'avance'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged, activeColor: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsItem() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final liveStats = data?['liveStats'] as Map<String, dynamic>? ?? {};

        final totalGifts = liveStats['totalGifts'] as int? ?? 0;
        final totalValue = liveStats['totalGiftValue'] as int? ?? 0;
        final totalViewers = liveStats['totalViewers'] as int? ?? 0;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Cadeaux reçus',
                  totalGifts.toString(),
                  Icons.card_giftcard,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Points gagnés',
                  totalValue.toString(),
                  Icons.star,
                  Colors.amber,
                ),
                _buildStatCard(
                  'Total spectateurs',
                  totalViewers.toString(),
                  Icons.visibility,
                  Colors.blue,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        tip,
        style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
      ),
    );
  }
}
