import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

import '../utils/permission_manager.dart';
import '../utils/simple_recording_manager.dart';
import '../widgets/live_interactions_widget.dart';
import '../widgets/live_overlay_widget.dart';
import '../widgets/live_stats_widget.dart';
import '../widgets/tiktok_live_interface.dart';

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
  bool _hasError = false;
  bool _isOffline = false;
  bool _disposed = false;
  Timer? _recordingStatusTimer;

  @override
  void initState() {
    super.initState();

    // Capturer les erreurs Flutter globales de manière plus sûre
    FlutterError.onError = (FlutterErrorDetails details) {
      // Vérifier si le widget est encore monté avant de modifier l'état
      if (mounted && !_disposed) {
        // Si l'erreur provient de ZegoUIKit, marquer comme erreur
        if (details.toString().contains('zego_uikit') ||
            details.toString().contains(
              'Null check operator used on a null value',
            ) ||
            details.toString().contains('_debugCurrentBuildTarget')) {
          // Utiliser un post-frame callback pour éviter les conflits de build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_disposed) {
              setState(() {
                _hasError = true;
              });
            }
          });
        }
      }
      // Toujours reporter l'erreur pour le debugging
      debugPrint('Flutter Error: ${details.toString()}');
    };

    _loadHostID();
    _updateViewerCount();

    // Démarrer l'enregistrement si c'est le host
    if (widget.isHost) {
      _startRecording();

      // Démarrer un timer pour mettre à jour l'affichage de l'enregistrement
      _recordingStatusTimer = Timer.periodic(const Duration(seconds: 1), (
        timer,
      ) {
        if (mounted && !_disposed) {
          setState(() {
            // Trigger rebuild pour mettre à jour l'indicateur d'enregistrement
          });
        }
      });
    }
  }

  Future<void> _loadHostID() async {
    if (_disposed) return; // Sortir si le widget est détruit

    try {
      if (widget.hostID != null) {
        _actualHostID = widget.hostID;
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('lives')
            .doc(widget.liveID)
            .get();

        if (doc.exists && mounted && !_disposed) {
          setState(() {
            _actualHostID = doc.data()!['id_host'] ?? widget.userID;
            _isOffline = false; // Connexion réussie
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'ID du host: $e');
      if (mounted && !_disposed) {
        setState(() {
          _actualHostID = widget.userID;
          _isOffline =
              e.toString().contains('UNAVAILABLE') ||
              e.toString().contains('SSLHandshakeException');
        });
      }
    }
  }

  Future<void> _updateViewerCount() async {
    if (!widget.isHost || _disposed) return; // Sortir si pas host ou détruit

    try {
      await FirebaseFirestore.instance
          .collection('lives')
          .doc(widget.liveID)
          .update({'stats.account': FieldValue.increment(1)});

      if (mounted && !_disposed) {
        setState(() {
          _isOffline = false; // Connexion réussie
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du nombre de spectateurs: $e');
      if (mounted && !_disposed) {
        setState(() {
          _isOffline =
              e.toString().contains('UNAVAILABLE') ||
              e.toString().contains('SSLHandshakeException');
        });
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      // Vérifier les permissions sans les demander
      final hasPermissions = await PermissionManager.hasEssentialPermissions();

      if (!hasPermissions) {
        // Afficher un message informatif au lieu de redemander
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Certaines permissions manquent - Enregistrement en mode simplifié',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Paramètres',
                textColor: Colors.white,
                onPressed: () {
                  PermissionManager.openSystemSettings();
                },
              ),
            ),
          );
        }
      }

      final recordingStarted = await SimpleRecordingManager.startRecording(
        widget.liveID,
      );

      if (recordingStarted) {
        debugPrint(
          '✅ Enregistrement natif démarré pour le live: ${widget.liveID}',
        );
        // Afficher une notification à l'utilisateur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    hasPermissions
                        ? '🎥 Enregistrement démarré automatiquement !'
                        : '📊 Capture des statistiques activée !',
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('❌ Échec du démarrage de l\'enregistrement natif');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('⚠️ Enregistrement indisponible - Live sans sauvegarde'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du démarrage de l\'enregistrement: $e');
    }
  }

  Future<void> _endLiveIfHost() async {
    try {
      if (widget.isHost) {
        // Arrêter l'enregistrement avant de terminer le live
        if (SimpleRecordingManager.isRecording()) {
          await SimpleRecordingManager.stopRecording(widget.liveID);
          debugPrint('✅ Enregistrement arrêté et sauvegardé');

          // Notifier l'utilisateur que l'enregistrement est sauvegardé
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '💾 Enregistrement sauvegardé ! Vous pourrez le regarder plus tard.',
                ),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }

        await FirebaseFirestore.instance
            .collection('lives')
            .doc(widget.liveID)
            .update({
              'is_live': false,
              'liveendtime': DateTime.now().millisecondsSinceEpoch,
            });
        debugPrint('Live terminé avec succès pour le host');
      } else {
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(widget.liveID)
            .update({'stats.account': FieldValue.increment(-1)});
        debugPrint('Spectateur retiré avec succès');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour Firestore: $e');
      // Ne pas relancer l'erreur pour éviter de bloquer la fermeture
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
    final config = ZegoUIKitPrebuiltLiveStreamingConfig.host();

    // Configuration audio/vidéo
    config.audioVideoView.showAvatarInAudioMode = true;

    // Masquer complètement la barre du haut de ZegoUIKit
    config.topMenuBar.showCloseButton = false;
    config.topMenuBar.height = 0;
    config.topMenuBar.padding = EdgeInsets.zero;
    config.topMenuBar.margin = EdgeInsets.zero;

    // Configuration de la barre du bas pour garder les boutons essentiels
    config.bottomMenuBar.showInRoomMessageButton =
        false; // Désactiver le chat ZegoUIKit
    config.bottomMenuBar.hostButtons = [
      ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
      ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
      ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
    ];
    config.bottomMenuBar.maxCount = 3;

    // Interface personnalisée
    config.foreground = _buildCustomForeground();
    config.background = _buildCustomBackground();

    // Configuration de l'enregistrement automatique (expérimental)
    // Note: Ces options pourraient ne pas être disponibles dans toutes les versions
    try {
      // Activer l'enregistrement automatique si disponible
      config.plugins = [];
      debugPrint(
        'Configuration d\'enregistrement initialisée pour le live: ${widget.liveID}',
      );
    } catch (e) {
      debugPrint(
        'Options d\'enregistrement non disponibles dans cette version: $e',
      );
    }

    return config;
  }

  // Configuration personnalisée pour les spectateurs
  ZegoUIKitPrebuiltLiveStreamingConfig _getAudienceConfig() {
    final config = ZegoUIKitPrebuiltLiveStreamingConfig.audience();
    config.audioVideoView.showAvatarInAudioMode = true;
    // Masquer complètement la barre du haut de ZegoUIKit pour l'audience
    config.topMenuBar.showCloseButton = false;
    config.topMenuBar.height = 0;
    config.topMenuBar.padding = EdgeInsets.zero;
    config.topMenuBar.margin = EdgeInsets.zero;
    // Configuration de la barre du bas - seulement le bouton micro pour l'audience
    config.bottomMenuBar.showInRoomMessageButton =
        false; // Désactiver le chat ZegoUIKit
    config.bottomMenuBar.audienceButtons = [
      ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
    ];
    config.bottomMenuBar.maxCount = 1;
    config.foreground = _buildCustomForeground();
    config.background = _buildCustomBackground();
    return config;
  }

  // Construire le foreground personnalisé avec l'interface de chat TikTok
  Widget _buildCustomForeground() {
    // Vérification plus robuste de l'hostID
    final hostID = _actualHostID ?? widget.hostID ?? widget.userID;

    return Stack(
      children: [
        // Interface TikTok complète (messages + chat en bas) - synchronisé avec Firestore
        TikTokLiveInterface(
          liveID: widget.liveID,
          userID: widget.userID,
          userName: widget.userName,
          isHost: widget.isHost,
        ),

        // Overlay avec les informations du host (en haut)
        LiveOverlayWidget(
          liveID: widget.liveID,
          userID: widget.userID,
          hostID: hostID,
          isHost: widget.isHost,
          onEndLive: _handleEndLive,
          onInvite: _handleInvite,
        ),

        // Interactions (likes, roses) - côté droit
        LiveInteractionsWidget(liveID: widget.liveID, userID: widget.userID),

        // Statistiques du live - en haut à droite
        LiveStatsWidget(liveID: widget.liveID),

        // Indicateur de connexion offline (si nécessaire)
        if (_isOffline)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Mode hors ligne - Fonctionnalités limitées',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Tentative de reconnexion
                      _loadHostID();
                      _updateViewerCount();
                    },
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Indicateur de statut d'enregistrement (si c'est le host)
        if (widget.isHost && SimpleRecordingManager.isRecording())
          Positioned(
            top: MediaQuery.of(context).padding.top + 110,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    SimpleRecordingManager.getRecordingStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
    _disposed = true; // Marquer le widget comme détruit

    // Restaurer le gestionnaire d'erreur par défaut
    FlutterError.onError = FlutterError.presentError;

    // Arrêter le timer de l'enregistrement
    _recordingStatusTimer?.cancel();

    // Appeler _endLiveIfHost de manière asynchrone pour éviter le blocage
    _endLiveIfHost().catchError((error) {
      debugPrint('Erreur lors de la fermeture du live: $error');
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Vérifications de sécurité
    if (_disposed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_actualHostID == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si une erreur ZegoUIKit a été détectée, afficher l'écran de fallback
    if (_hasError) {
      return Scaffold(body: _buildFallbackScreen());
    }

    return WillPopScope(
      onWillPop: () async {
        try {
          if (widget.isHost) {
            // Pour le host, afficher une confirmation avant de quitter
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Arrêter le live'),
                content: const Text(
                  'Êtes-vous sûr de vouloir arrêter ce live ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Arrêter',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (result == true) {
              await _endLiveIfHost();
              return true; // Permettre la sortie
            }
            return false; // Empêcher la sortie
          } else {
            // Pour l'audience, quitter directement
            await _endLiveIfHost(); // Décrémenter le compteur de spectateurs
            return true; // Permettre la sortie
          }
        } catch (e) {
          debugPrint('Erreur lors de la fermeture: $e');
          // En cas d'erreur, forcer la sortie pour éviter que l'utilisateur reste bloqué
          return true;
        }
      },
      child: Scaffold(
        body: Builder(
          builder: (context) {
            try {
              return ZegoUIKitPrebuiltLiveStreaming(
                appID: 1635546276,
                appSign:
                    'f8a71bf0e57d934cda48369c059ea936375a67f088be3a5183b8efb147b28d3d',
                userID: widget.userID,
                userName: widget.userName,
                liveID: widget.liveID,
                config: widget.isHost ? _getHostConfig() : _getAudienceConfig(),
              );
            } catch (e) {
              debugPrint('Erreur lors de la construction de ZegoUIKit: $e');
              // En cas d'erreur, afficher un écran de fallback
              return _buildFallbackScreen();
            }
          },
        ),
      ),
    );
  }

  // Écran de fallback en cas d'erreur ZegoUIKit
  Widget _buildFallbackScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOffline ? Icons.wifi_off : Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _isOffline
                  ? 'Problème de connexion réseau'
                  : 'Erreur de connexion au live',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isOffline
                  ? 'Vérifiez votre connexion Internet'
                  : 'Une erreur technique est survenue',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _disposed
                      ? null
                      : () {
                          // Utiliser un post-frame callback pour éviter les erreurs de build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_disposed) {
                              setState(() {
                                _hasError = false; // Réinitialiser l'erreur
                                _isOffline =
                                    false; // Réinitialiser l'état offline
                              });
                              // Tentative de reconnexion
                              _loadHostID();
                              _updateViewerCount();
                            }
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isOffline ? 'Reconnecter' : 'Réessayer'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
