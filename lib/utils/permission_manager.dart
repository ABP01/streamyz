import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestionnaire centralisé des permissions pour éviter les demandes répétées
class PermissionManager {
  static bool _initialized = false;
  static final Map<Permission, PermissionStatus> _cachedStatuses = {};

  // Clés pour sauvegarder l'état des permissions
  static const String _keyPermissionsChecked = 'permissions_checked';
  static const String _keyMicrophoneGranted = 'microphone_granted';
  static const String _keyStorageGranted = 'storage_granted';
  static const String _keyCameraGranted = 'camera_granted';

  /// Initialise le gestionnaire de permissions (à appeler au démarrage de l'app)
  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🔐 Initialisation du gestionnaire de permissions...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCheckedBefore = prefs.getBool(_keyPermissionsChecked) ?? false;

      if (hasCheckedBefore) {
        // Charger les statuts sauvegardés
        await _loadCachedPermissions();
        debugPrint('✅ Permissions chargées depuis le cache');
      } else {
        // Première fois - demander les permissions essentielles
        await _requestEssentialPermissions();
      }

      _initialized = true;
      debugPrint('✅ Gestionnaire de permissions initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation permissions: $e');
      _initialized = true; // Continuer quand même
    }
  }

  /// Charge les permissions depuis le cache
  static Future<void> _loadCachedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Charger les statuts depuis les préférences ET vérifier l'état actuel
      final microphoneGranted = prefs.getBool(_keyMicrophoneGranted) ?? false;
      final storageGranted = prefs.getBool(_keyStorageGranted) ?? false;
      final cameraGranted = prefs.getBool(_keyCameraGranted) ?? false;

      // Vérifier l'état actuel (au cas où l'utilisateur aurait changé dans les paramètres)
      final currentMicStatus = await Permission.microphone.status;
      final currentStorageStatus = await Permission.storage.status;
      final currentCameraStatus = await Permission.camera.status;

      _cachedStatuses[Permission.microphone] = currentMicStatus;
      _cachedStatuses[Permission.storage] = currentStorageStatus;
      _cachedStatuses[Permission.camera] = currentCameraStatus;

      debugPrint('📊 Permissions actuelles:');
      debugPrint('  🎤 Microphone: $currentMicStatus');
      debugPrint('  💾 Storage: $currentStorageStatus');
      debugPrint('  📷 Camera: $currentCameraStatus');
    } catch (e) {
      debugPrint('❌ Erreur chargement cache permissions: $e');
    }
  }

  /// Demande les permissions essentielles (seulement la première fois)
  static Future<void> _requestEssentialPermissions() async {
    try {
      debugPrint('🔐 Première demande des permissions essentielles...');

      // Liste des permissions importantes pour Streamyz
      final permissions = [
        Permission.microphone,
        Permission.storage,
        Permission.camera,
      ];

      // Demander toutes les permissions en une fois
      final statuses = await permissions.request();

      // Sauvegarder les résultats
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPermissionsChecked, true);

      for (final entry in statuses.entries) {
        final permission = entry.key;
        final status = entry.value;

        _cachedStatuses[permission] = status;

        // Sauvegarder individuellement
        if (permission == Permission.microphone) {
          await prefs.setBool(
            _keyMicrophoneGranted,
            status == PermissionStatus.granted,
          );
        } else if (permission == Permission.storage) {
          await prefs.setBool(
            _keyStorageGranted,
            status == PermissionStatus.granted,
          );
        } else if (permission == Permission.camera) {
          await prefs.setBool(
            _keyCameraGranted,
            status == PermissionStatus.granted,
          );
        }

        if (status == PermissionStatus.granted) {
          debugPrint('✅ ${permission.toString().split('.').last}: accordée');
        } else {
          debugPrint('⚠️ ${permission.toString().split('.').last}: $status');
        }
      }

      debugPrint('✅ Configuration initiale des permissions terminée');
    } catch (e) {
      debugPrint('❌ Erreur demande permissions initiales: $e');
    }
  }

  /// Vérifie si une permission spécifique est accordée (sans la demander)
  static Future<bool> isGranted(Permission permission) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // Vérifier le cache d'abord
      if (_cachedStatuses.containsKey(permission)) {
        final cachedStatus = _cachedStatuses[permission]!;
        if (cachedStatus == PermissionStatus.granted) {
          return true;
        }
      }

      // Vérifier l'état actuel si pas dans le cache ou pas accordée
      final currentStatus = await permission.status;
      _cachedStatuses[permission] = currentStatus;

      return currentStatus == PermissionStatus.granted;
    } catch (e) {
      debugPrint('❌ Erreur vérification permission $permission: $e');
      return false;
    }
  }

  /// Vérifie si toutes les permissions essentielles sont accordées
  static Future<bool> hasEssentialPermissions() async {
    try {
      final microphone = await isGranted(Permission.microphone);
      final storage = await isGranted(Permission.storage);
      final camera = await isGranted(Permission.camera);

      debugPrint(
        '🎯 Permissions essentielles: Micro=$microphone, Storage=$storage, Camera=$camera',
      );

      // Au minimum, on a besoin du microphone pour les lives
      return microphone;
    } catch (e) {
      debugPrint('❌ Erreur vérification permissions essentielles: $e');
      return false;
    }
  }

  /// Demande une permission spécifique seulement si nécessaire
  static Future<bool> requestIfNeeded(Permission permission) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // Vérifier si déjà accordée
      final isAlreadyGranted = await isGranted(permission);
      if (isAlreadyGranted) {
        debugPrint(
          '✅ Permission ${permission.toString().split('.').last} déjà accordée',
        );
        return true;
      }

      // Demander seulement si pas accordée
      debugPrint(
        '🔐 Demande permission ${permission.toString().split('.').last}...',
      );
      final status = await permission.request();

      // Mettre à jour le cache
      _cachedStatuses[permission] = status;

      // Sauvegarder
      await _updateSavedPermission(permission, status);

      final granted = status == PermissionStatus.granted;
      debugPrint(
        granted
            ? '✅ Permission accordée: ${permission.toString().split('.').last}'
            : '❌ Permission refusée: ${permission.toString().split('.').last} ($status)',
      );

      return granted;
    } catch (e) {
      debugPrint('❌ Erreur demande permission $permission: $e');
      return false;
    }
  }

  /// Met à jour une permission sauvegardée
  static Future<void> _updateSavedPermission(
    Permission permission,
    PermissionStatus status,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGranted = status == PermissionStatus.granted;

      if (permission == Permission.microphone) {
        await prefs.setBool(_keyMicrophoneGranted, isGranted);
      } else if (permission == Permission.storage) {
        await prefs.setBool(_keyStorageGranted, isGranted);
      } else if (permission == Permission.camera) {
        await prefs.setBool(_keyCameraGranted, isGranted);
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde permission: $e');
    }
  }

  /// Ouvre les paramètres de l'application pour permettre à l'utilisateur de modifier les permissions
  static Future<void> openSystemSettings() async {
    try {
      debugPrint('📱 Ouverture des paramètres de l\'application...');
      final success = await openAppSettings();
      debugPrint(
        success ? '✅ Paramètres ouverts' : '❌ Échec ouverture paramètres',
      );
    } catch (e) {
      debugPrint('❌ Erreur ouverture paramètres: $e');
    }
  }

  /// Remet à zéro toutes les permissions sauvegardées (pour debugging)
  static Future<void> resetPermissions() async {
    try {
      debugPrint('🔄 Reset des permissions sauvegardées...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPermissionsChecked);
      await prefs.remove(_keyMicrophoneGranted);
      await prefs.remove(_keyStorageGranted);
      await prefs.remove(_keyCameraGranted);

      _cachedStatuses.clear();
      _initialized = false;

      debugPrint('✅ Permissions reset - prochaine demande sera complète');
    } catch (e) {
      debugPrint('❌ Erreur reset permissions: $e');
    }
  }

  /// Obtient un résumé des permissions pour debugging
  static Future<Map<String, dynamic>> getPermissionsSummary() async {
    try {
      final microphone = await isGranted(Permission.microphone);
      final storage = await isGranted(Permission.storage);
      final camera = await isGranted(Permission.camera);

      return {
        'initialized': _initialized,
        'microphone': microphone,
        'storage': storage,
        'camera': camera,
        'hasEssential': await hasEssentialPermissions(),
        'cached_count': _cachedStatuses.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
