import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../utils/firestore_helper.dart';

class TikTokLiveInterface extends StatefulWidget {
  final String liveID;
  final String userID;
  final String userName;
  final bool isHost;

  const TikTokLiveInterface({
    super.key,
    required this.liveID,
    required this.userID,
    required this.userName,
    required this.isHost,
  });

  @override
  State<TikTokLiveInterface> createState() => _TikTokLiveInterfaceState();
}

class _TikTokLiveInterfaceState extends State<TikTokLiveInterface>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Chat> _messages = [];
  final List<String> _joinedUsers = [];
  final Map<String, String> _userNames = {}; // Mappage ID -> Nom
  bool _showSendButton = false;
  Timer? _joinTimer;

  @override
  void initState() {
    super.initState();

    // Ajouter l'utilisateur actuel au mappage
    _userNames[widget.userID] = widget.userName;

    _listenToMessages();
    _startJoinNotifications();

    _focusNode.addListener(() {
      setState(() {
        _showSendButton = _focusNode.hasFocus;
      });
    });

    _messageController.addListener(() {
      // Le bouton s'affiche seulement avec le focus
    });
  }

  void _listenToMessages() {
    FirebaseFirestore.instance
        .collection('chats')
        .where('live_id', isEqualTo: widget.liveID)
        // .orderBy('time', descending: false) // Commenté temporairement pour éviter l'erreur d'index
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added && mounted) {
              final chat = Chat.fromMap(change.doc.data()!);

              // Récupérer le vrai nom d'utilisateur depuis Firebase
              if (!_userNames.containsKey(chat.idUser)) {
                _loadUserName(chat.idUser);
              }

              setState(() {
                _messages.add(chat);

                // Trier manuellement par temps pour compenser l'absence d'orderBy
                _messages.sort((a, b) {
                  if (a.time == null || b.time == null) return 0;
                  return a.time!.compareTo(b.time!);
                });

                // Limiter à 10 messages max
                if (_messages.length > 10) {
                  _messages.removeAt(0);
                }
              });

              debugPrint(
                'Nouveau message reçu: ${chat.message} de ${_userNames[chat.idUser]}',
              );

              // Retirer le message après 8 secondes
              Future.delayed(const Duration(seconds: 8), () {
                if (mounted) {
                  setState(() {
                    _messages.removeWhere((msg) => msg.idChat == chat.idChat);
                  });
                }
              });
            }
          }
        });
  }

  void _startJoinNotifications() {
    // Notifications de rejoignement réelles supprimées
    // Les vraies notifications peuvent être ajoutées via Firestore si nécessaire
  }

  void _addJoinNotification() {
    // Méthode conservée pour compatibilité mais ne génère plus de faux utilisateurs
  }

  // Récupérer le vrai nom d'utilisateur depuis Firebase
  Future<void> _loadUserName(String userId) async {
    try {
      final userName = await FirestoreHelper.getUserName(userId);
      if (mounted) {
        setState(() {
          _userNames[userId] = userName;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du nom d\'utilisateur: $e');
      // En cas d'erreur, utiliser l'ID comme fallback
      if (mounted) {
        setState(() {
          _userNames[userId] = userId;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc();
      final chat = Chat(
        liveId: widget.liveID,
        idChat: chatRef.id,
        idHost: widget.isHost ? widget.userID : '',
        message: message,
        idUser: widget.userID, // Utiliser userID pour l'ID
        time: DateTime.now(),
      );

      await chatRef.set(chat.toMap());
      _messageController.clear();
      _focusNode.unfocus();

      setState(() {
        _showSendButton = false;
      });

      debugPrint('Message envoyé avec succès: ${chat.message}');
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Messages qui défilent (style TikTok)
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications de connexion
              ..._joinedUsers.map(
                (username) => TikTokJoinNotification(
                  key: ValueKey(username),
                  username: username,
                ),
              ),

              const SizedBox(height: 8),

              // Messages de chat
              ..._messages.map(
                (chat) => TikTokScrollingMessage(
                  key: ValueKey(chat.idChat),
                  chat: chat,
                  userName: _userNames[chat.idUser] ?? chat.idUser,
                ),
              ),
            ],
          ),
        ),

        // Interface de chat en bas (simplifiée)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
            child: Row(
              children: [
                // Champ de saisie (largeur réduite)
                Container(
                  width: 200, // Largeur fixe réduite
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                // Bouton d'envoi (apparaît seulement avec focus)
                if (_showSendButton) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _joinTimer?.cancel();
    super.dispose();
  }
}

class TikTokScrollingMessage extends StatelessWidget {
  final Chat chat;
  final String userName;

  const TikTokScrollingMessage({
    super.key,
    required this.chat,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 12),
          ),

          const SizedBox(width: 8),

          // Message
          Flexible(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$userName ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: chat.message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TikTokJoinNotification extends StatelessWidget {
  final String username;

  const TikTokJoinNotification({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Icône de connexion
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add, color: Colors.white, size: 10),
          ),

          const SizedBox(width: 8),

          // Texte de notification
          Text(
            '@$username Joined',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
