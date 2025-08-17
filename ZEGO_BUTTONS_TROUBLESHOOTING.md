# Guide de Dépannage - Boutons ZegoUIKit

## Problèmes Identifiés et Solutions

### 1. Boutons ZegoUIKit ne fonctionnent pas

**Problème :** Les boutons ZegoUIKit (microphone, caméra, etc.) ne répondent pas aux clics.

**Causes possibles :**
- Interface personnalisée couvre les boutons
- Configuration incorrecte des boutons
- Conflit avec les widgets personnalisés

**Solutions appliquées :**

#### A. Correction de la configuration des boutons

```dart
// Configuration pour le host
config.bottomMenuBar.hostButtons = [
  ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
  ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
  ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
  ZegoLiveStreamingMenuBarButtonName.leaveButton,
];
config.bottomMenuBar.maxCount = 4;

// Configuration pour l'audience
config.bottomMenuBar.audienceButtons = [
  ZegoLiveStreamingMenuBarButtonName.leaveButton,
];
config.bottomMenuBar.maxCount = 1;
```

#### B. Espacement pour les boutons

```dart
// Dans _buildCustomForeground()
Positioned(
  top: 0,
  left: 0,
  right: 0,
  bottom: 80, // Laisser de l'espace pour les boutons ZegoUIKit
  child: TikTokLiveInterface(...),
),
```

#### C. Style des boutons

```dart
// Rendre les boutons plus visibles
config.bottomMenuBar.backgroundColor = Colors.black.withOpacity(0.3);
```

### 2. Test des Boutons

Utilisez le widget de test `ZegoButtonsTest` pour vérifier le fonctionnement :

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ZegoButtonsTest(
      userID: 'test_user',
      userName: 'Test User',
      liveID: 'test_live',
      isHost: true, // ou false pour audience
    ),
  ),
);
```

### 3. Vérifications à faire

1. **Permissions :** Vérifiez que les permissions caméra/microphone sont accordées
2. **Version ZegoUIKit :** Assurez-vous d'utiliser la dernière version
3. **AppID/AppSign :** Vérifiez que les identifiants Zego sont corrects
4. **Connexion réseau :** Assurez-vous d'avoir une connexion stable

### 4. Configuration Recommandée

```dart
ZegoUIKitPrebuiltLiveStreamingConfig _getHostConfig() {
  final config = ZegoUIKitPrebuiltLiveStreamingConfig.host();
  
  // Permissions
  config.turnOnCameraWhenJoining = true;
  config.turnOnMicrophoneWhenJoining = true;
  config.useSpeakerWhenJoining = true;
  
  // Barre du haut
  config.topMenuBar.showCloseButton = false;
  config.topMenuBar.height = 0;
  
  // Barre du bas
  config.bottomMenuBar.showInRoomMessageButton = false;
  config.bottomMenuBar.hostButtons = [
    ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
    ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
    ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
    ZegoLiveStreamingMenuBarButtonName.leaveButton,
  ];
  config.bottomMenuBar.maxCount = 4;
  config.bottomMenuBar.backgroundColor = Colors.black.withOpacity(0.3);
  
  return config;
}
```

### 5. Dépannage Avancé

Si les boutons ne fonctionnent toujours pas :

1. **Désactivez temporairement l'interface personnalisée :**
   ```dart
   // Commenter ces lignes
   // config.foreground = _buildCustomForeground();
   // config.background = _buildCustomBackground();
   ```

2. **Testez avec une configuration minimale :**
   ```dart
   ZegoUIKitPrebuiltLiveStreamingConfig.host()
   ```

3. **Vérifiez les logs de débogage :**
   ```dart
   debugPrint('Configuration des boutons: ${config.bottomMenuBar.hostButtons}');
   ```

### 6. Boutons Disponibles

Boutons supportés pour le host :
- `toggleMicrophoneButton` - Activer/désactiver le microphone
- `toggleCameraButton` - Activer/désactiver la caméra
- `switchCameraButton` - Changer de caméra (avant/arrière)
- `leaveButton` - Quitter le live

Boutons supportés pour l'audience :
- `leaveButton` - Quitter le live

### 7. Notes Importantes

- Les boutons ZegoUIKit sont gérés nativement par le SDK
- L'interface personnalisée ne doit pas couvrir la zone des boutons
- Le `maxCount` doit correspondre au nombre de boutons dans la liste
- Les boutons sont automatiquement positionnés en bas de l'écran
