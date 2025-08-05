# 🔍 Guide pour Voir les Récapitulatifs Azure - Streamyz

## ✅ TOKEN SAS MIS À JOUR

Votre nouveau token SAS Azure a été configuré avec les **permissions complètes** :

```
Token: sp=racwdl&st=2025-08-05T16:30:12Z&se=2025-09-30T00:45:12Z&sv=2024-11-04&sr=c&sig=Vu%2BjnQg8vv3VebczR0Lb2mm4p75X%2FwfFO2jzSIS%2BPVk%3D

URL complète: https://streamyzstorage.blob.core.windows.net/livespasses?sp=racwdl&st=2025-08-05T16:30:12Z&se=2025-09-30T00:45:12Z&sv=2024-11-04&sr=c&sig=Vu%2BjnQg8vv3VebczR0Lb2mm4p75X%2FwfFO2jzSIS%2BPVk%3D
```

### 🔑 Permissions Incluses
- `r` = read (lecture) ✅
- `a` = add (ajout) ✅  
- `c` = create (création) ✅
- `w` = write (écriture) ✅
- `d` = delete (suppression) ✅
- `l` = list (listage) ✅

## 🎯 Comment Voir les Récapitulatifs sur Azure

### 1. **Via l'Application Streamyz**

#### Méthode recommandée :
1. **Lancez l'app** : `flutter run`
2. **Démarrez un nouveau live** avec enregistrement
3. **Laissez tourner 1-2 minutes** pour générer du contenu
4. **Arrêtez le live** 
5. **Allez dans "Pour vous"** → Vous devriez voir le live avec badge "ENREGISTRÉ"
6. **Cliquez dessus** → Le récapitulatif s'affiche

### 2. **Via le Navigateur Web (Test Direct)**

Ouvrez cette URL dans votre navigateur pour voir tous les fichiers :
```
https://streamyzstorage.blob.core.windows.net/livespasses?restype=container&comp=list&sp=racwdl&st=2025-08-05T16:30:12Z&se=2025-09-30T00:45:12Z&sv=2024-11-04&sr=c&sig=Vu%2BjnQg8vv3VebczR0Lb2mm4p75X%2FwfFO2jzSIS%2BPVk%3D
```

### 3. **Via Azure Storage Explorer**

1. Téléchargez Azure Storage Explorer
2. Connectez-vous avec l'URL SAS complète
3. Naviguez vers le container `livespasses`
4. Vous verrez tous les fichiers uploadés

## 🔍 Types de Fichiers à Chercher

### Enregistrements d'Écran
```
Nom: live_[LIVE_ID].gif
Format: Animation GIF de l'écran
Taille: Variable selon durée
Exemple: live_ABC123_1754410488796.gif
```

### Récapitulatifs Vidéo
```
Nom: live_[LIVE_ID].mp4  
Format: Vidéo MP4
Taille: Variable selon durée
Exemple: live_ABC123_1754410488796.mp4
```

### Métadonnées
```
Nom: live_[LIVE_ID]_recap.json
Format: Données JSON
Contenu: Stats du live, durée, spectateurs, etc.
```

## 🚨 Résolution des Problèmes

### Si vous ne voyez pas de récapitulatifs :

#### **Problème 1 : Ancien token sans permissions**
✅ **RÉSOLU** - Nouveau token avec permissions complètes installé

#### **Problème 2 : Pas d'enregistrements générés**
**Solution** : Créer un nouveau live test
```bash
1. flutter run
2. Démarrer un live test
3. Attendre 30 secondes minimum
4. Arrêter le live
5. Vérifier l'upload dans les logs
```

#### **Problème 3 : Logs d'erreur upload**
**Vérifications** :
- [ ] Token SAS valide (expire le 6 août 00:34)
- [ ] Container `livespasses` existe
- [ ] Permissions complètes activées
- [ ] Connexion internet stable

### Logs à Surveiller

**Upload réussi :**
```
✅ Enregistrement uploadé avec succès: live_XXX.mp4
☁️ URL Azure: https://streamyzstorage.blob.core.windows.net/livespasses/live_XXX.mp4
```

**Upload échoué :**
```
❌ Erreur upload Azure: [CODE] - [MESSAGE]
```

## 🧪 Test Rapide

### Commande de test direct (dans votre terminal) :

```bash
# Test de listage des fichiers
curl "https://streamyzstorage.blob.core.windows.net/livespasses?restype=container&comp=list&sp=racwdl&st=2025-08-05T16:30:12Z&se=2025-09-30T00:45:12Z&sv=2024-11-04&sr=c&sig=Vu%2BjnQg8vv3VebczR0Lb2mm4p75X%2FwfFO2jzSIS%2BPVk%3D"
```

Cette commande vous montrera tous les fichiers actuellement stockés sur Azure.

## ⏰ Expiration du Token

**ATTENTION** : Ce token expire le **30 septembre 2025 à 00:45**.

Pour continuer à utiliser Azure après cette date, vous devrez :
1. Générer un nouveau token SAS dans Azure Portal
2. Mettre à jour les fichiers `azure_storage_service.dart` et `home_screen.dart`
3. Rebuilder l'application

## 🎯 Prochaines Étapes

1. **Testez immédiatement** avec le nouveau token
2. **Créez un live de test** pour vérifier l'upload
3. **Vérifiez les récaps** dans l'app et sur Azure
4. **Générez un nouveau token** avant expiration

Le système est maintenant prêt à uploader vos enregistrements ! 🚀
