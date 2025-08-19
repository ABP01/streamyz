import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

import '../widgets/live_controls_widget.dart';
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
  bool _isEndingLive = false; // Flag pour éviter le double dialogue

  @override
  void initState() {
    super.initState();

    // Capturer les erreurs Flutter globales de manière plus sûre
    FlutterError.onError = (FlutterErrorDetails details) {
      // Vérifier si le widget est encore monté avant de modifier l'état
      if (mounted && !_disposed && !_isEndingLive) {
        // Si l'erreur provient de ZegoUIKit, marquer comme erreur
        if (details.toString().contains('zego_uikit') ||
            details.toString().contains(
              'ZegoUIKitPrebuiltLiveStreamingState',
            ) ||
            details.toString().contains(
              'Null check operator used on a null value',
            ) ||
            details.toString().contains('_debugCurrentBuildTarget') ||
            details.toString().contains('normalPage')) {
          // Utiliser un post-frame callback pour éviter les conflits de build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_disposed && !_isEndingLive) {
              debugPrint(
                '🔴 Erreur ZegoUIKit détectée, basculement vers fallback',
              );
              setState(() {
                _hasError = true;
              });

              // Forcer la fermeture après un délai pour éviter les boucles
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted && !_disposed) {
                  Navigator.of(context).pop();
                }
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

  Future<void> _endLiveIfHost() async {
    try {
      if (widget.isHost) {
        // Arrêter l'enregistrement avant de terminer le live

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
    if (_isEndingLive) return; // Éviter les appels multiples

    setState(() {
      _isEndingLive = true; // Marquer qu'on est en train de terminer
    });

    try {
      // Arrêter l'enregistrement et mettre à jour Firestore
      await _endLiveIfHost();

      // Donner un délai pour permettre à ZegoUIKit de se nettoyer
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(); // Quitter directement
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt du live: $e');
      // En cas d'erreur, forcer la fermeture après un délai
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
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

    // Permissions et fonctionnalités
    config.turnOnCameraWhenJoining = true;
    config.turnOnMicrophoneWhenJoining = true;
    config.useSpeakerWhenJoining = true;

    // Masquer complètement la barre du haut de ZegoUIKit
    config.topMenuBar.showCloseButton = false;
    config.topMenuBar.height = 0;
    config.topMenuBar.padding = EdgeInsets.zero;
    config.topMenuBar.margin = EdgeInsets.zero;

    // Masquer complètement la barre du bas de ZegoUIKit pour éviter les conflits
    config.bottomMenuBar.showInRoomMessageButton = false;
    config.bottomMenuBar.hostButtons = []; // Aucun bouton ZegoUIKit
    config.bottomMenuBar.maxCount = 0;
    config.bottomMenuBar.height = 0;
    config.bottomMenuBar.padding = EdgeInsets.zero;
    config.bottomMenuBar.margin = EdgeInsets.zero;

    // Interface personnalisée - utiliser notre propre interface
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

    // Permissions pour l'audience
    config.turnOnCameraWhenJoining = false;
    config.turnOnMicrophoneWhenJoining = false;
    config.useSpeakerWhenJoining = true;
    // Masquer complètement la barre du haut de ZegoUIKit pour l'audience
    config.topMenuBar.showCloseButton = false;
    config.topMenuBar.height = 0;
    config.topMenuBar.padding = EdgeInsets.zero;
    config.topMenuBar.margin = EdgeInsets.zero;
    // Configuration de la barre du bas pour l'audience
    config.bottomMenuBar.showInRoomMessageButton = false;
    config.bottomMenuBar.audienceButtons = [];
    config.bottomMenuBar.maxCount = 0;

    // Configuration du style des boutons pour l'audience
    config.bottomMenuBar.backgroundColor = Colors.black.withOpacity(0.7);
    config.foreground = _buildCustomForeground();
    config.background = _buildCustomBackground();
    return config;
  }

  // Construire le foreground personnalisé avec l'interface de chat TikTok
  Widget _buildCustomForeground() {
    // Si on est en train de terminer le live, retourner un container vide
    if (_disposed || _isEndingLive) {
      return Container();
    }

    // Vérification plus robuste de l'hostID
    final hostID = _actualHostID ?? widget.hostID ?? widget.userID;

    return Stack(
      children: [
        // Interface TikTok complète (messages + chat en bas) - synchronisé avec Firestore
        // Positionner pour laisser de l'espace pour nos contrôles personnalisés
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 100, // Laisser de l'espace pour nos contrôles
          child: TikTokLiveInterface(
            liveID: widget.liveID,
            userID: widget.userID,
            userName: widget.userName,
            isHost: widget.isHost,
          ),
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

        // Contrôles personnalisés (remplace l'interface ZegoUIKit)
        LiveControlsWidget(
          isHost: widget.isHost,
          onEndLive: _handleEndLive,
          onInvite: _handleInvite,
        ),

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

    // Appeler _endLiveIfHost seulement si on n'est pas déjà en train de terminer
    if (!_isEndingLive) {
      _endLiveIfHost().catchError((error) {
        debugPrint('Erreur lors de la fermeture du live: $error');
      });
    }

    // Marquer qu'on termine pour empêcher tout nouveau traitement
    _isEndingLive = true;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Vérifications de sécurité
    if (_disposed || _isEndingLive) {
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
          // Si on est déjà en train de terminer le live via le bouton, laisser passer
          if (_isEndingLive) {
            return true;
          }

          if (widget.isHost) {
            // Pour le host, arrêter directement sans dialogue
            setState(() {
              _isEndingLive = true;
            });

            await _endLiveIfHost();

            // Donner un délai pour permettre à ZegoUIKit de se nettoyer
            await Future.delayed(const Duration(milliseconds: 300));

            return true; // Permettre la sortie
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
                  onPressed: (_disposed || _isEndingLive)
                      ? null
                      : () {
                          // Utiliser un post-frame callback pour éviter les erreurs de build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_disposed && !_isEndingLive) {
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
