# Streamyz

Streamyz est une application Flutter permettant de créer, rejoindre et explorer des lives vidéo en temps réel, avec gestion des utilisateurs, profils, et interactions sociales.

## Fonctionnalités

- **Authentification** : Inscription et connexion via email/password (Firebase Auth).
- **Profil utilisateur** : Modification du profil, avatar, bio, abonnements, paramètres de confidentialité.
- **Lives vidéo** : Démarrage d'un live, upload de miniature (Azure Blob Storage), affichage des anciens lives et lives en cours.
- **Explorer** : Découverte des lives en cours.
- **Paramètres** : Gestion du thème (clair/sombre), visibilité des followers, déconnexion.
- **Gestion des données** : Stockage des utilisateurs et lives dans Firestore.

## Structure du projet

- `lib/screens/` : Écrans principaux (authentification, profil, home, explorer, paramètres, édition du profil, live).
- `lib/models/` : Modèles de données (User, Live, Livestats, Donateur, Chat).
- `lib/main.dart` : Point d'entrée de l'application, gestion du thème et de la navigation principale.

## Démarrage rapide

1. **Pré-requis** :
   - Flutter installé ([installation](https://docs.flutter.dev/get-started/install))
   - Un projet Firebase configuré (Firestore, Auth)
   - Un compte Azure Blob Storage pour les miniatures et avatars

2. **Installation des dépendances** :
   ```bash
   flutter pub get
   ```

3. **Configuration Firebase** :
   - Ajoutez vos fichiers `google-services.json` (Android) et `GoogleService-Info.plist` (iOS) dans les dossiers appropriés.

4. **Lancement de l'application** :
   ```bash
   flutter run
   ```

## Personnalisation

- Modifiez les paramètres Azure dans les fichiers concernés (`home_screen.dart`, `edit_profile_screen.dart`) pour utiliser vos propres clés SAS et containers.
- Les modèles Firestore sont personnalisables dans `models/`.

## Ressources utiles

- [Documentation Flutter](https://docs.flutter.dev/)
- [Firebase pour Flutter](https://firebase.flutter.dev/)
- [Zego UIKit Prebuilt Live Streaming](https://docs.zegocloud.com/)
- [Azure Blob Storage](https://learn.microsoft.com/fr-fr/azure/storage/blobs/)

---
Projet réalisé avec Flutter, Firebase et Azure.
