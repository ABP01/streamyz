import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LiveStatsPage extends StatelessWidget {
  const LiveStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Live'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Top Streamers'),
                Tab(text: 'Top Gifters'),
              ],
              labelColor: Colors.white,
              indicatorColor: Colors.red,
            ),
            Expanded(
              child: TabBarView(
                children: [_buildTopStreamers(), _buildTopGifters()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStreamers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('liveStats.totalGiftValue', isGreaterThan: 0)
          .orderBy('liveStats.totalGiftValue', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Aucun streamer trouvé',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final streamers = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: streamers.length,
          itemBuilder: (context, index) {
            final streamerData =
                streamers[index].data() as Map<String, dynamic>;
            final liveStats =
                streamerData['liveStats'] as Map<String, dynamic>? ?? {};
            final username =
                streamerData['username'] ??
                streamerData['displayName'] ??
                'Streamer ${index + 1}';
            final totalValue = liveStats['totalGiftValue'] as int? ?? 0;
            final totalGifts = liveStats['totalGifts'] as int? ?? 0;
            final isLive = streamerData['isLive'] == true;

            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[700],
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isLive)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$totalGifts cadeaux reçus',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$totalValue',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopGifters() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('gifts')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Aucun cadeau envoyé',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        // Regrouper les cadeaux par expéditeur
        final Map<String, Map<String, dynamic>> gifterStats = {};

        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final senderId = data['senderId'] as String;
          final senderName = data['senderName'] as String;
          final giftType = data['giftType'] as String;

          int giftValue = 1; // heart
          if (giftType == 'star') giftValue = 5;
          if (giftType == 'diamond') giftValue = 10;

          if (!gifterStats.containsKey(senderId)) {
            gifterStats[senderId] = {
              'name': senderName,
              'totalValue': 0,
              'totalGifts': 0,
            };
          }

          gifterStats[senderId]!['totalValue'] += giftValue;
          gifterStats[senderId]!['totalGifts'] += 1;
        }

        // Trier par valeur totale
        final sortedGifters = gifterStats.entries.toList()
          ..sort(
            (a, b) => (b.value['totalValue'] as int).compareTo(
              a.value['totalValue'] as int,
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedGifters.length.clamp(0, 20),
          itemBuilder: (context, index) {
            final gifter = sortedGifters[index];
            final stats = gifter.value;

            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[700],
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  stats['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${stats['totalGifts']} cadeaux envoyés',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats['totalValue']}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
