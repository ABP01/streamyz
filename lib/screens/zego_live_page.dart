import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

import '../widgets/live_interactions_widget.dart';
import '../widgets/live_message_input.dart';
import '../widgets/live_overlay_widget.dart';
import '../widgets/live_stats_widget.dart';
import '../widgets/tiktok_style_messages.dart';

class ZegoLivePage extends StatefulWidget {
  final String liveID;
  final String userID;
  final String userName;
  final bool isHost;
  final String? hostID;

  const ZegoLivePage({
    super.key,
    required this.liveID,
    required this.userID,
    required this.userName,
    required this.isHost,
    this.hostID,
  });

  @override
  State<ZegoLivePage> createState() => _ZegoLivePageState();
}

class _ZegoLivePageState extends State<ZegoLivePage> {
  String? _actualHostID;

  @override
  void initState() {
    super.initState();
    _loadHostID();
    _updateViewerCount();
  }

  Future<void> _loadHostID() async {
    try {
      if (widget.hostID != null) {
        _actualHostID = widget.hostID;
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('lives')
            .doc(widget.liveID)
            .get();

        if (doc.exists) {
          setState(() {
            _actualHostID = doc.data()!['id_host'] ?? widget.userID;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'ID du host: $e');
      _actualHostID = widget.userID;
    }
  }

  Future<void> _updateViewerCount() async {
    if (!widget.isHost) {
      try {
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(widget.liveID)
            .update({'stats.account': FieldValue.increment(1)});
      } catch (e) {
        debugPrint(
          'Erreur lors de la mise à jour du nombre de spectateurs: $e',
        );
      }
    }
  }

  Future<void> _endLiveIfHost() async {
    if (widget.isHost) {
      try {
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(widget.liveID)
            .update({
              'is_live': false,
              'liveendtime': DateTime.now().millisecondsSinceEpoch,
            });
      } catch (e) {
        debugPrint('Erreur lors de la fin du live: $e');
      }
    } else {
      try {
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(widget.liveID)
            .update({'stats.account': FieldValue.increment(-1)});
      } catch (e) {
        debugPrint(
          'Erreur lors de la mise à jour du nombre de spectateurs: $e',
        );
      }
    }
  }

  Future<void> _handleEndLive() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arrêter le live'),
        content: const Text('Êtes-vous sûr de vouloir arrêter ce live ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Arrêter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _endLiveIfHost();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleInvite() async {
    try {
      final liveUrl = 'streamyz://live/${widget.liveID}';
      await Share.share(
        'Rejoignez-moi en live sur Streamyz! $liveUrl',
        subject: 'Live sur Streamyz',
      );
    } catch (e) {
      debugPrint('Erreur lors du partage: $e');
    }
  }

  // Configuration personnalisée pour le host
  ZegoUIKitPrebuiltLiveStreamingConfig _getHostConfig() {
    return ZegoUIKitPrebuiltLiveStreamingConfig.host()
      ..audioVideoView.showAvatarInAudioMode = true
      // Masquer complètement la barre du haut de ZegoUIKit
      ..topMenuBar.showCloseButton = false
      ..topMenuBar.height = 0
      ..topMenuBar.padding = EdgeInsets.zero
      ..topMenuBar.margin = EdgeInsets.zero
      // Configuration de la barre du bas pour garder seulement les boutons essentiels
      ..bottomMenuBar.showInRoomMessageButton = false
      ..bottomMenuBar.hostButtons = [
        ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
        ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
        ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
      ]
      ..bottomMenuBar.maxCount = 3
      ..foreground = _buildCustomForeground()
      ..background = _buildCustomBackground();
  }

  // Configuration personnalisée pour les spectateurs
  ZegoUIKitPrebuiltLiveStreamingConfig _getAudienceConfig() {
    return ZegoUIKitPrebuiltLiveStreamingConfig.audience()
      ..audioVideoView.showAvatarInAudioMode = true
      // Masquer complètement la barre du haut de ZegoUIKit
      ..topMenuBar.showCloseButton = false
      ..topMenuBar.height = 0
      ..topMenuBar.padding = EdgeInsets.zero
      ..topMenuBar.margin = EdgeInsets.zero
      // Configuration de la barre du bas - pas de boutons pour les spectateurs
      ..bottomMenuBar.showInRoomMessageButton = false
      ..bottomMenuBar.maxCount = 0
      ..foreground = _buildCustomForeground()
      ..background = _buildCustomBackground();
  }

  // Construire le foreground personnalisé avec tous nos widgets
  Widget _buildCustomForeground() {
    if (_actualHostID == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Messages style TikTok qui défilent
        TikTokStyleMessages(liveID: widget.liveID),

        // Overlay avec les informations du host
        LiveOverlayWidget(
          liveID: widget.liveID,
          userID: widget.userID,
          hostID: _actualHostID!,
          isHost: widget.isHost,
          onEndLive: _handleEndLive,
          onInvite: _handleInvite,
        ),

        // Interactions (likes, roses) - côté droit
        LiveInteractionsWidget(liveID: widget.liveID, userID: widget.userID),

        // Statistiques du live
        LiveStatsWidget(liveID: widget.liveID),

        // Input de message style TikTok
        LiveMessageInput(
          liveID: widget.liveID,
          userID: widget.userID,
          userName: widget.userName,
          isHost: widget.isHost,
        ),
      ],
    );
  }

  // Background personnalisé
  Widget _buildCustomBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.black54, Colors.black87],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _endLiveIfHost();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_actualHostID == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ZegoUIKitPrebuiltLiveStreaming(
        appID: 1635546276,
        appSign:
            'f8a71bf0e57d934cda48369c059ea936375a67f088be3a5183b8efb147b28d3d',
        userID: widget.userID,
        userName: widget.userName,
        liveID: widget.liveID,
        config: widget.isHost ? _getHostConfig() : _getAudienceConfig(),
      ),
    );
  }
}
