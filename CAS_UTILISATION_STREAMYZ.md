# 📋 Descriptions des Cas d'Utilisation - Application Streamyz

---

## Cas d'utilisation 1 : Création et démarrage d'un live

### SOMMAIRE D'IDENTIFICATION
**Titre :** Création et démarrage d'un live streaming  
**Résumé :** L'animateur (HOST) crée un nouveau live avec titre et description, puis démarre la diffusion en temps réel.  
**Acteurs :** HOST (Animateur)  
**Auteur :** Équipe Streamyz  
**Date de création :** 22/01/2025  
**Date de mise à jour :** 22/01/2025  
**Version :** 1.0  

**Préconditions :**
- L'utilisateur est authentifié sur l'application
- L'utilisateur a accordé les permissions caméra et microphone
- L'utilisateur dispose d'une connexion internet stable

### DESCRIPTION DES SCENARIOS

**Scénario nominal**
1. L'utilisateur accède à l'interface "Démarrer Live" (E1)
2. L'utilisateur saisit le titre et la description du live (E2)
3. Le système vérifie que les champs obligatoires sont remplis (A1)
4. Le système vérifie les permissions caméra/microphone (A2)
5. L'utilisateur confirme le démarrage du live
6. Le système génère un ID unique pour le live
7. Le système démarre l'enregistrement automatique
8. Le système publie le live dans la liste des lives actifs
9. Le système affiche l'interface de diffusion avec contrôles

**Scénario alternatif**  
**A1 :** L'utilisateur a oublié de remplir le titre ou la description. Ce scénario alternatif est déclenché au point 3 du scénario nominal  
→ Le système affiche "Veuillez ajouter une description". Le déroulement reprend au point 2 du scénario nominal

**A2 :** Les permissions caméra/microphone ne sont pas accordées. Ce scénario alternatif est déclenché au point 4 du scénario nominal  
→ Le système affiche un message d'information avec bouton vers les paramètres. Le déroulement reprend au point 1 du scénario nominal

**Scénario d'exception**  
**E1 :** L'utilisateur annule l'opération. Ce scénario d'exception est déclenché au point 1 du scénario nominal  
→ Le scénario nominal est interrompu, retour à l'écran d'accueil

**E2 :** Perte de connexion internet. Ce scénario d'exception peut se déclencher à tout moment  
→ Le système affiche un message d'erreur et propose de réessayer

**Post conditions**
- Le live est créé et actif dans la base de données
- L'enregistrement automatique est démarré
- Le live apparaît dans la liste des lives disponibles pour l'audience
- L'interface de diffusion est opérationnelle avec tous les contrôles

---

## Cas d'utilisation 2 : Rejoindre un live

### SOMMAIRE D'IDENTIFICATION
**Titre :** Rejoindre un live en tant que spectateur  
**Résumé :** L'audience découvre et rejoint un live streaming actif pour le regarder et interagir.  
**Acteurs :** AUDIENCE (Spectateurs)  
**Auteur :** Équipe Streamyz  
**Date de création :** 22/01/2025  
**Date de mise à jour :** 22/01/2025  
**Version :** 1.0  

**Préconditions :**
- L'utilisateur a accès à l'application (connexion optionnelle)
- Au moins un live est actif sur la plateforme
- L'utilisateur dispose d'une connexion internet stable

### DESCRIPTION DES SCENARIOS

**Scénario nominal**
1. L'utilisateur parcourt la liste des lives actifs (E1)
2. L'utilisateur sélectionne un live à rejoindre
3. Le système vérifie la disponibilité du live (A1)
4. Le système charge l'interface de visionnage
5. Le système établit la connexion au stream vidéo
6. L'utilisateur voit le stream en direct avec chat et interactions
7. Le système met à jour le compteur de spectateurs

**Scénario alternatif**  
**A1 :** Le live sélectionné s'est terminé entre temps. Ce scénario alternatif est déclenché au point 3 du scénario nominal  
→ Le système affiche "Ce live s'est terminé" et propose d'autres lives actifs. Le déroulement reprend au point 1 du scénario nominal

**Scénario d'exception**  
**E1 :** Aucun live n'est disponible. Ce scénario d'exception est déclenché au point 1 du scénario nominal  
→ L'application affiche "Aucun live en cours" avec suggestion de consulter les enregistrements

**Post conditions**
- L'utilisateur est connecté au stream en direct
- Le compteur de spectateurs est mis à jour
- L'interface de chat et d'interactions est accessible
- L'utilisateur peut participer aux interactions du live

---

## Cas d'utilisation 3 : Communiquer via chat

### SOMMAIRE D'IDENTIFICATION
**Titre :** Communication temps réel via chat  
**Résumé :** HOST et AUDIENCE échangent des messages en temps réel pendant le live streaming.  
**Acteurs :** HOST (Animateur), AUDIENCE (Spectateurs)  
**Auteur :** Équipe Streamyz  
**Date de création :** 22/01/2025  
**Date de mise à jour :** 22/01/2025  
**Version :** 1.0  

**Préconditions :**
- L'utilisateur a rejoint un live actif
- L'utilisateur est authentifié pour envoyer des messages
- Le chat n'est pas désactivé par l'animateur

### DESCRIPTION DES SCENARIOS

**Scénario nominal**
1. L'utilisateur accède à l'interface de chat dans le live (E1)
2. L'utilisateur saisit son message dans le champ de texte (E2)
3. Le système vérifie que le message n'est pas vide (A1)
4. Le système vérifie la longueur du message (A2)
5. L'utilisateur appuie sur "Envoyer"
6. Le système sauvegarde le message dans Firestore
7. Le système diffuse le message à tous les spectateurs connectés
8. Le message apparaît dans le chat avec badge spécial si c'est le HOST
9. Le chat scroll automatiquement vers le bas

**Scénario alternatif**  
**A1 :** Le message est vide. Ce scénario alternatif est déclenché au point 3 du scénario nominal  
→ Le bouton "Envoyer" reste inactif. L'utilisateur doit saisir du texte

**A2 :** Le message dépasse la limite de caractères. Ce scénario alternatif est déclenché au point 4 du scénario nominal  
→ Le système tronque le message et affiche un indicateur de limite. Le déroulement continue normalement

**Scénario d'exception**  
**E1 :** Le live se termine pendant la saisie. Ce scénario d'exception peut se déclencher à tout moment  
→ L'interface de chat se désactive et affiche "Live terminé"

**E2 :** Perte de connexion. Ce scénario d'exception est déclenché au point 2 du scénario nominal  
→ Le système met en file d'attente le message et le renvoie lors de la reconnexion

**Post conditions**
- Le message est visible par tous les spectateurs du live
- L'historique des messages est conservé
- Le compteur d'activité du live est mis à jour
- Le scroll automatique maintient la vue sur les derniers messages

---

## Cas d'utilisation 4 : Envoyer des interactions

### SOMMAIRE D'IDENTIFICATION
**Titre :** Envoi d'interactions (likes et cadeaux)  
**Résumé :** L'audience exprime son appréciation via likes et roses (cadeaux virtuels) avec animations.  
**Acteurs :** AUDIENCE (Spectateurs)  
**Auteur :** Équipe Streamyz  
**Date de création :** 22/01/2025  
**Date de mise à jour :** 22/01/2025  
**Version :** 1.0  

**Préconditions :**
- L'utilisateur a rejoint un live actif
- L'interface d'interactions est visible
- Le live accepte les interactions

### DESCRIPTION DES SCENARIOS

**Scénario nominal**
1. L'utilisateur voit les boutons d'interaction (cœur et rose) (E1)
2. L'utilisateur appuie sur le bouton "Like" ou "Rose"
3. Le système enregistre l'interaction dans Firestore (A1)
4. Le système met à jour les statistiques du live
5. Le système déclenche l'animation flottante correspondante
6. Le système notifie le HOST de la nouvelle interaction
7. Les compteurs sont mis à jour en temps réel pour tous les spectateurs

**Scénario alternatif**  
**A1 :** Problème de sauvegarde dans Firestore. Ce scénario alternatif est déclenché au point 3 du scénario nominal  
→ Le système réessaie automatiquement la sauvegarde en arrière-plan. L'animation s'affiche normalement

**Scénario d'exception**  
**E1 :** Le live se termine pendant l'interaction. Ce scénario d'exception est déclenché au point 1 du scénario nominal  
→ Les boutons d'interaction se désactivent et affichent "Live terminé"

**Post conditions**
- L'interaction est comptabilisée dans les statistiques du live
- L'animation correspondante a été affichée
- Le HOST voit la mise à jour des statistiques
- L'historique des interactions est conservé

---

## Cas d'utilisation 5 : Contrôler le streaming

### SOMMAIRE D'IDENTIFICATION
**Titre :** Contrôle des paramètres de streaming  
**Résumé :** L'animateur gère les paramètres audio/vidéo de sa diffusion pendant le live.  
**Acteurs :** HOST (Animateur)  
**Auteur :** Équipe Streamyz  
**Date de création :** 22/01/2025  
**Date de mise à jour :** 22/01/2025  
**Version :** 1.0  

**Préconditions :**
- L'utilisateur a démarré un live
- Les permissions caméra/microphone sont accordées
- L'interface de contrôles est accessible

### DESCRIPTION DES SCENARIOS

**Scénario nominal**
1. L'utilisateur accède aux contrôles de streaming (boutons micro, caméra, flip)
2. L'utilisateur appuie sur un bouton de contrôle (E1)
3. Le système vérifie l'état actuel du paramètre (A1)
4. Le système applique la modification (activation/désactivation)
5. Le système met à jour l'interface utilisateur (icône, couleur)
6. Le système applique le changement au stream en direct
7. Tous les spectateurs voient la modification instantanément

**Scénario alternatif**  
**A1 :** Permission révoquée par l'utilisateur. Ce scénario alternatif est déclenché au point 3 du scénario nominal  
→ Le système affiche un message d'erreur et redirige vers les paramètres. L'action est annulée

**Scénario d'exception**  
**E1 :** Problème technique avec la caméra/micro. Ce scénario d'exception est déclenché au point 2 du scénario nominal  
→ Le système affiche une notification d'erreur et maintient l'état précédent

**Post conditions**
- Le paramètre de streaming est modifié selon la demande
- L'interface reflète le nouvel état
- Les spectateurs voient la modification en temps réel
- L'état des contrôles est sauvegardé pour la session

---

## Cas d'utilisation 6 : Gérer les enregistrements

### SOMMAIRE D'IDENTIFICATION
**Titre :** Gestion des enregistrements de lives  
**Résumé :** HOST et AUDIENCE consultent, partagent et gèrent les replays de lives automatiquement sauvegardés.  
**Acteurs :** HOST (Animateur), AUDIENCE (Spectateurs)  
**Auteur :** Équipe Streamyz  
**Date de création :** 22/01/2025  
**Date de mise à jour :** 22/01/2025  
**Version :** 1.0  

**Préconditions :**
- Au moins un live a été terminé et enregistré
- L'utilisateur a accès à l'onglet "Pour vous" ou "Enregistrements"
- Les enregistrements sont stockés sur Azure Storage

### DESCRIPTION DES SCENARIOS

**Scénario nominal**
1. L'utilisateur accède à l'onglet des enregistrements (E1)
2. Le système charge la liste des enregistrements disponibles (A1)
3. L'utilisateur sélectionne un enregistrement à consulter
4. Le système charge les métadonnées et statistiques du live
5. L'utilisateur visualise le recap avec graphiques et données
6. L'utilisateur peut partager, supprimer (si propriétaire) ou revoir l'enregistrement

**Scénario alternatif**  
**A1 :** Aucun enregistrement disponible. Ce scénario alternatif est déclenché au point 2 du scénario nominal  
→ Le système affiche "Aucun enregistrement disponible" avec suggestion de faire un live

**Scénario d'exception**  
**E1 :** Erreur de chargement depuis Azure. Ce scénario d'exception est déclenché au point 1 du scénario nominal  
→ Le système affiche un message d'erreur et propose de réessayer

**Post conditions**
- L'utilisateur a consulté les statistiques de l'enregistrement
- Les actions demandées (partage, suppression) ont été exécutées
- L'historique de consultation est mis à jour
- Les métadonnées restent cohérentes dans le système 