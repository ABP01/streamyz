import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

const int appID = 1145966523;
const String appSign =
    "718e87c3fe2843726ed28a6dd25197aac29eb8016d442cc84151c07b65e95d2d";

class LiveStreamBasePage extends StatefulWidget {
  const LiveStreamBasePage({super.key});

  @override
  State<LiveStreamBasePage> createState() => _LiveStreamBasePageState();
}

class _LiveStreamBasePageState extends State<LiveStreamBasePage> {
  final TextEditingController _liveIdController = TextEditingController();
  String? _userName;
  String? _userId;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userName =
            doc.data()?['username'] ??
            doc.data()?['displayName'] ??
            user.displayName ??
            user.email ??
            user.uid;
        _loadingUser = false;
      });
    } else {
      setState(() {
        _userName = 'Utilisateur';
        _userId = 'user';
        _loadingUser = false;
      });
    }
  }

  @override
  void dispose() {
    _liveIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveID = "1234";
    final streamUrl =
        'https://webliveroom-demo.zegocloud.com?app_id=$appID&stream_id=$liveID';

    if (_loadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userId = _userId ?? 'user';
    final userName = _userName ?? 'Utilisateur';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Live Streaming",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Informations du live",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.white,
              elevation: 3,
              shadowColor: Theme.of(
                context,
              ).colorScheme.secondary.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      "ID du live :",
                      liveID,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: liveID));
                        _showMessage(context, 'ID du live copié !');
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      "URL du live :",
                      streamUrl,
                      fontSize: 13,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: streamUrl));
                        _showMessage(context, 'URL du live copiée !');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint('Démarrer le live');
                  debugPrint("User ID: $userId");
                  debugPrint("Live Id: $liveID");
                  debugPrint("Username: $userName");

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ZegoLiveStream(
                        uid: userId,
                        userName: userName,
                        liveID: liveID,
                        isHost: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.videocam),
                label: const Text("Démarrer le live"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary, // Orange
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
              ),
            ),
            const Divider(height: 40),
            Text(
              "Rejoindre un live avec un ID personnalisé",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _liveIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Entrer l\'ID du live',
                prefixIcon: Icon(Icons.live_tv),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  final id = _liveIdController.text.trim();
                  if (id.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ZegoLiveStream(
                          uid: userId,
                          userName: userName,
                          liveID: id,
                          isHost: false,
                        ),
                      ),
                    );
                  } else {
                    _showMessage(context, 'Veuillez entrer un ID de live.');
                  }
                },
                icon: const Icon(Icons.login, color: Color(0xFF001F3F)),
                label: const Text("Rejoindre avec cet ID"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF001F3F), // Bleu marine
                  side: const BorderSide(color: Color(0xFF001F3F), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Suppression de la section "Rejoindre en tant qu'utilisateur" et des boutons fictifs
            const Divider(height: 40),
            Text(
              "Lives en cours",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isLive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Aucun live en cours.');
                }
                final users = snapshot.data!.docs;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    final userName =
                        user['username'] ?? user['displayName'] ?? userId;
                    final liveID = 'live_$userId';
                    return ListTile(
                      leading: const Icon(Icons.live_tv, color: Colors.red),
                      title: Text(userName),
                      subtitle: Text('ID: $liveID'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ZegoLiveStream(
                                uid: userId,
                                userName: userName,
                                liveID: liveID,
                                isHost: false,
                              ),
                            ),
                          );
                        },
                        child: const Text('Rejoindre'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String title,
    String value, {
    double fontSize = 15,
    required VoidCallback onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontSize: fontSize,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy, size: 20),
          tooltip: "Copier",
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}

class ZegoLiveStream extends StatefulWidget {
  const ZegoLiveStream({
    super.key,
    required this.uid,
    required this.userName,
    required this.liveID,
    required this.isHost,
  });
  final String uid;
  final String userName;
  final String liveID;
  final bool isHost;

  @override
  State<ZegoLiveStream> createState() => _ZegoLiveStreamState();
}

class _ZegoLiveStreamState extends State<ZegoLiveStream> {
  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltLiveStreaming(
      appID: appID,
      appSign: appSign,
      userID: widget.uid,
      userName: widget.userName,
      liveID: widget.liveID,
      config: widget.isHost
          ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
          : ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
    );
  }
}
