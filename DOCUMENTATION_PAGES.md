# Documentation des Pages - Application Streamyz

## Vue d'ensemble de l'application

Streamyz est une application de streaming en direct et de réseau social qui permet aux utilisateurs de :
- Créer et rejoindre des streams en direct
- Publier et consulter des posts
- Chatter en temps réel
- Rechercher et suivre d'autres utilisateurs
- Gérer leur profil et leurs paramètres de live

---

## Architecture de l'application

### Structure des dossiers
```
lib/views/
├── auth/           # Pages d'authentification
├── home/           # Pages principales de l'application
└── drawer_screen.dart
```

---

## Pages d'Authentification

### 1. LoginPage (`lib/views/auth/login.dart`)

**Description :** Page de connexion permettant aux utilisateurs de s'authentifier avec email/mot de passe.

**Fonctionnalités :**
- Validation des champs email et mot de passe
- Authentification Firebase
- Gestion d'erreurs avec messages d'erreur localisés
- Navigation automatique vers la page d'accueil après connexion réussie
- Lien vers la page d'inscription

**User Story :**
*En tant qu'utilisateur non connecté, je veux pouvoir me connecter avec mon email et mot de passe pour accéder à l'application.*

**Workflow utilisateur :**
1. L'utilisateur ouvre l'application
2. Il saisit son email et mot de passe
3. Il clique sur "Se connecter"
4. Le système valide les informations
5. En cas de succès : redirection vers HomePage
6. En cas d'erreur : affichage du message d'erreur

**Actions disponibles :**
- Saisie email/mot de passe
- Bouton "Se connecter"
- Lien "S'inscrire" vers SignupPage

---

### 2. Signup (`lib/views/auth/signup.dart`)

**Description :** Page d'inscription permettant aux nouveaux utilisateurs de créer un compte.

**Fonctionnalités :**
- Création de compte avec email, mot de passe et nom d'utilisateur
- Validation des champs (username max 10 caractères)
- Création automatique du document utilisateur dans Firestore
- Stockage du nom d'utilisateur en version lowercase pour la recherche

**User Story :**
*En tant que nouvel utilisateur, je veux pouvoir créer un compte avec un nom d'utilisateur unique pour rejoindre la communauté Streamyz.*

**Workflow utilisateur :**
1. L'utilisateur clique sur "S'inscrire" depuis LoginPage
2. Il saisit username, email et mot de passe
3. Il clique sur "S'inscrire"
4. Le système crée le compte Firebase et le document Firestore
5. Redirection automatique vers HomePage

**Actions disponibles :**
- Saisie username (max 10 caractères)
- Saisie email
- Saisie mot de passe
- Bouton "S'inscrire"

---

## Pages Principales (Home)

### 3. HomePage (`lib/views/home/home_page.dart`)

**Description :** Page d'accueil principale avec navigation par onglets et gestion des posts.

**Fonctionnalités :**
- Navigation par onglets (Post, Chat, Live, Explore)
- Section de création et affichage des posts
- Drawer avec profil et déconnexion
- Gestion spéciale de l'onglet Explore pour les nouveaux utilisateurs
- FloatingActionButton pour accès rapide aux lives

**User Story :**
*En tant qu'utilisateur connecté, je veux avoir accès à toutes les fonctionnalités de l'application depuis une interface centralisée.*

**Workflow utilisateur :**
1. Après connexion, l'utilisateur arrive sur l'onglet "Post"
2. Il peut publier un nouveau post
3. Il peut naviguer entre les onglets
4. Il peut accéder au menu drawer
5. Il peut rechercher d'autres utilisateurs via l'icône search

**Actions disponibles :**
- Publication de posts texte
- Navigation entre onglets
- Accès au drawer menu
- Recherche d'utilisateurs
- Accès rapide aux lives (FAB)

**Onglets :**
- **Post :** Création et consultation des posts
- **Chat :** Liste des conversations
- **Live :** Interface de streaming
- **Explore :** Interface immersive pour découvrir les lives actifs

---

### 4. ExplorePage (`lib/views/home/explore_page.dart`)

**Description :** Page d'exploration immersive qui affiche les lives actifs dans une interface similaire à ImmersiveLiveViewerPage.

**Fonctionnalités :**
- Affichage automatique des lives actifs depuis Firestore
- Interface immersive plein écran pour la découverte
- Gestion des états de chargement et d'erreur
- Message d'encouragement quand aucun live n'est disponible
- Intégration avec ImmersiveLiveViewerPage

**User Story :**
*En tant qu'utilisateur, je veux pouvoir découvrir facilement les lives actifs dans une interface immersive pour explorer le contenu disponible.*

**Workflow utilisateur :**
1. L'utilisateur clique sur l'onglet "Explore"
2. Il accède automatiquement au premier live disponible
3. Il peut voir le stream en mode immersif
4. Si aucun live n'est disponible, il peut démarrer le sien
5. Navigation fluide vers les fonctionnalités de streaming

**Actions disponibles :**
- Visionnage automatique du premier live disponible
- Interface immersive complète
- Navigation vers l'onglet Live pour créer son propre stream
- Gestion des erreurs avec messages informatifs

---

### 5. ChatPage (`lib/views/home/chat.dart`)

**Description :** Interface de chat en temps réel avec gestion des conversations et messages.

**Fonctionnalités :**
- Liste des conversations actives triées par date
- Interface de chat en temps réel
- Envoi de messages avec timestamp
- Gestion des participants
- Actions de suppression de conversations (swipe)
- Navigation vers profils utilisateurs

**User Story :**
*En tant qu'utilisateur, je veux pouvoir communiquer en privé avec d'autres utilisateurs via un système de chat en temps réel.*

**Workflow utilisateur :**
1. L'utilisateur accède à l'onglet Chat
2. Il voit la liste de ses conversations
3. Il peut ouvrir une conversation existante
4. Il peut envoyer des messages
5. Il peut supprimer des conversations (swipe left)
6. Il peut accéder au profil de son interlocuteur

**Actions disponibles :**
- Consultation des conversations
- Envoi de messages
- Suppression de conversations
- Navigation vers profils
- Démarrage de live avec contact

---

### 5. ChatPage (`lib/views/home/chat.dart`)

**Description :** Interface de chat en temps réel avec gestion des conversations et messages.

**Fonctionnalités :**
- Liste des conversations actives triées par date
- Interface de chat en temps réel
- Envoi de messages avec timestamp
- Gestion des participants
- Actions de suppression de conversations (swipe)
- Navigation vers profils utilisateurs

**User Story :**
*En tant qu'utilisateur, je veux pouvoir communiquer en privé avec d'autres utilisateurs via un système de chat en temps réel.*

**Workflow utilisateur :**
1. L'utilisateur accède à l'onglet Chat
2. Il voit la liste de ses conversations
3. Il peut ouvrir une conversation existante
4. Il peut envoyer des messages
5. Il peut supprimer des conversations (swipe left)
6. Il peut accéder au profil de son interlocuteur

**Actions disponibles :**
- Consultation des conversations
- Envoi de messages
- Suppression de conversations
- Navigation vers profils
- Démarrage de live avec contact

---

### 6. SearchPage (`lib/views/home/search.dart`)

**Description :** Page de recherche d'utilisateurs avec fonctionnalités de suivi.

**Fonctionnalités :**
- Recherche d'utilisateurs par nom d'utilisateur (3+ caractères)
- Affichage des résultats avec statut de suivi
- Boutons Follow/Unfollow
- Navigation vers profils utilisateurs
- Démarrage de conversations

**User Story :**
*En tant qu'utilisateur, je veux pouvoir rechercher et découvrir d'autres utilisateurs pour étendre mon réseau.*

**Workflow utilisateur :**
1. L'utilisateur clique sur l'icône search
2. Il tape un nom d'utilisateur (minimum 3 caractères)
3. Les résultats s'affichent en temps réel
4. Il peut suivre/ne plus suivre des utilisateurs
5. Il peut accéder aux profils
6. Il peut démarrer une conversation

**Actions disponibles :**
- Recherche en temps réel
- Follow/Unfollow utilisateurs
- Navigation vers profils
- Démarrage de conversations

---

### 7. ProfilePage (`lib/views/home/profile.dart`)

**Description :** Page de profil utilisateur avec informations et actions disponibles.

**Fonctionnalités :**
- Affichage des informations utilisateur
- Indicateur de statut live
- Bouton pour rejoindre le live si actif
- Statistiques de suivi
- Actions selon le type de profil (propre profil vs autre utilisateur)

**User Story :**
*En tant qu'utilisateur, je veux pouvoir consulter les profils des autres utilisateurs et voir leur statut d'activité.*

**Workflow utilisateur :**
1. L'utilisateur accède à un profil via search, chat, etc.
2. Il consulte les informations de l'utilisateur
3. Si l'utilisateur est en live, il peut rejoindre
4. Il peut voir les statistiques de followers/following

**Actions disponibles :**
- Consultation du profil
- Rejoindre le live (si actif)
- Voir les statistiques de suivi

---

### 8. LiveStreamBasePage (`lib/views/home/live_stream.dart`)

**Description :** Interface principale de streaming avec création et gestion des lives.

**Fonctionnalités :**
- Interface de streaming Zego Cloud
- Génération automatique d'ID de live
- Informations de streaming (ID, URL)
- Configuration des paramètres de live
- Boutons pour démarrer/arrêter le live
- Copie des informations de partage

**User Story :**
*En tant qu'utilisateur, je veux pouvoir créer et diffuser mes propres streams en direct pour partager du contenu avec ma communauté.*

**Workflow utilisateur :**
1. L'utilisateur accède à l'onglet Live
2. Il voit ses informations de streaming
3. Il peut configurer ses paramètres
4. Il démarre son live
5. Il peut partager les informations de connexion
6. Il gère son stream en temps réel

**Actions disponibles :**
- Démarrage/arrêt du live
- Configuration des paramètres
- Copie des informations de partage
- Gestion du stream en temps réel

---

### 9. ImmersiveLiveViewerPage (`lib/views/home/immersive_live_viewer.dart`)

**Description :** Visionneuse immersive pour regarder les streams d'autres utilisateurs.

**Fonctionnalités :**
- Interface immersive plein écran
- Chat live intégré
- Système de cadeaux virtuels avec animations
- Statistiques en temps réel (viewers, gifts)
- Animations de cœurs et cadeaux flottants
- Contrôles de lecture
- Gestion des interactions sociales

**User Story :**
*En tant qu'utilisateur, je veux pouvoir regarder les streams d'autres utilisateurs dans une interface immersive avec possibilité d'interaction en temps réel.*

**Workflow utilisateur :**
1. L'utilisateur rejoint un live depuis un profil ou une liste
2. Il regarde le stream en plein écran
3. Il peut chatter avec les autres viewers
4. Il peut envoyer des cadeaux virtuels
5. Il voit les animations et statistiques en temps réel
6. Il peut quitter le live

**Actions disponibles :**
- Visionnage du stream
- Chat en temps réel
- Envoi de cadeaux virtuels
- Interaction avec animations
- Contrôles de lecture

---

### 10. LiveStatsPage (`lib/views/home/live_stats.dart`)

**Description :** Page de statistiques et classements des lives.

**Fonctionnalités :**
- Classement des top streamers
- Classement des top gifters
- Statistiques détaillées par utilisateur
- Système d'onglets pour différentes métriques
- Affichage des valeurs de cadeaux

**User Story :**
*En tant qu'utilisateur, je veux pouvoir voir les classements et statistiques de la communauté pour découvrir les streamers populaires.*

**Workflow utilisateur :**
1. L'utilisateur accède aux statistiques
2. Il consulte le classement des streamers
3. Il peut changer d'onglet pour voir les gifters
4. Il découvre les utilisateurs populaires
5. Il peut naviguer vers leurs profils

**Actions disponibles :**
- Consultation des classements
- Navigation entre onglets
- Accès aux profils des top utilisateurs

---

### 11. LiveSettingsPage (`lib/views/home/live_settings.dart`)

**Description :** Page de configuration des paramètres de streaming.

**Fonctionnalités :**
- Configuration des permissions (cadeaux, commentaires)
- Notification des followers
- Paramètres d'enregistrement
- Sauvegarde automatique des préférences
- Interface de switches pour activation/désactivation

**User Story :**
*En tant qu'utilisateur streameur, je veux pouvoir configurer mes préférences de live pour contrôler l'expérience de diffusion.*

**Workflow utilisateur :**
1. L'utilisateur accède aux paramètres live
2. Il configure ses préférences (cadeaux, commentaires, etc.)
3. Les paramètres sont sauvegardés automatiquement
4. Il peut revenir en arrière ou continuer

**Actions disponibles :**
- Configuration des permissions
- Activation/désactivation des fonctionnalités
- Sauvegarde automatique

---

### 13. ExplorePage (`lib/views/home/explore_page.dart`)

**Description :** Interface d'exploration des lives actifs avec navigation de type TikTok.

**Fonctionnalités :**
- Affichage des lives actifs en temps réel
- Interface de défilement vertical (comme TikTok)
- Navigation entre lives par swipe vertical
- Indicateurs visuels de position
- Lecture automatique du live visible
- Instructions de navigation intégrées
- Gestion des états (chargement, erreur, aucun live)

**User Story :**
*En tant qu'utilisateur, je veux pouvoir découvrir et parcourir les lives actifs dans une interface immersive similaire à TikTok.*

**Workflow utilisateur :**
1. L'utilisateur clique sur l'onglet "Explore"
2. Il voit le premier live disponible en plein écran
3. Il peut faire défiler vers le haut/bas pour changer de live
4. Chaque live se charge automatiquement
5. Il voit les indicateurs de position à droite
6. Il peut interagir avec chaque live individuellement

**Actions disponibles :**
- Défilement vertical entre lives
- Interaction avec chaque live (chat, cadeaux)
- Visualisation des indicateurs de navigation
- Retour à l'accueil si aucun live
- Démarrage de son propre live

---

### 12. ChatList (`lib/views/home/chat_list.dart`)

**Description :** Liste organisée des conversations avec aperçu des derniers messages.

**Fonctionnalités :**
- Liste des conversations triées par activité
- Aperçu du dernier message
- Photos de profil des correspondants
- Indicateurs de messages non lus
- Navigation vers conversations individuelles

**User Story :**
*En tant qu'utilisateur, je veux voir toutes mes conversations organisées avec un aperçu rapide pour gérer mes communications.*

**Workflow utilisateur :**
1. L'utilisateur accède à la liste des chats
2. Il voit ses conversations triées par activité
3. Il peut ouvrir une conversation spécifique
4. Il voit les aperçus des derniers messages

**Actions disponibles :**
- Consultation de la liste des conversations
- Navigation vers conversations individuelles
- Recherche de nouvelles conversations

---

### 13. DrawerScreen (`lib/views/drawer_screen.dart`)

**Description :** Menu latéral de navigation avec options principales.

**Fonctionnalités :**
- Navigation vers le profil utilisateur
- Option de déconnexion
- Design cohérent avec l'interface

**User Story :**
*En tant qu'utilisateur, je veux avoir accès à un menu de navigation pour les actions principales comme voir mon profil ou me déconnecter.*

**Workflow utilisateur :**
1. L'utilisateur ouvre le drawer
2. Il peut accéder à son profil
3. Il peut se déconnecter
4. Il est redirigé selon son choix

**Actions disponibles :**
- Accès au profil personnel
- Déconnexion
- Navigation dans l'application

---

## Workflows Principaux

### Workflow d'Onboarding
1. **Nouvelle installation** → LoginPage
2. **Première inscription** → Signup → HomePage
3. **Connexion existante** → LoginPage → HomePage

### Workflow de Streaming
1. **Créer un live** → LiveStreamBasePage → Configuration → Démarrage
2. **Regarder un live** → Profil/Recherche → ImmersiveLiveViewerPage
3. **Interaction live** → Chat + Cadeaux → Animations

### Workflow Social
1. **Découverte** → SearchPage → Profils → Follow
2. **Communication** → ChatPage → Messages privés
3. **Partage** → Posts → Comments → Interactions

### Workflow de Configuration
1. **Paramètres live** → LiveSettingsPage → Configuration
2. **Profil** → ProfilePage → Modifications
3. **Statistiques** → LiveStatsPage → Analyse

---

## Technologies et Intégrations

- **Firebase Auth** : Authentification utilisateur
- **Cloud Firestore** : Base de données en temps réel
- **Zego Cloud** : Infrastructure de streaming
- **Flutter** : Framework de développement
- **Material Design** : Interface utilisateur

---

## Notes Techniques

- L'application utilise un système de navigation par onglets (IndexedStack)
- Les données sont synchronisées en temps réel via Firestore
- Les animations sont gérées via des AnimationControllers
- Le streaming utilise l'intégration Zego UIKit
- La gestion d'état utilise StatefulWidget avec setState()

---

*Documentation générée pour l'application Streamyz - Version courante sur la branche features/live*
