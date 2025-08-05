# 🎯 Guide de Test Rapide - Récapitulatifs Azure

## ✅ TOKEN MIS À JOUR - TESTONS MAINTENANT !

Votre nouveau token Azure avec **permissions complètes** est configuré. Voici comment tester immédiatement :

## 🚀 Test en 5 Minutes

### 1. **Test de Connexion Azure** (30 secondes)
Ouvrez cette URL dans votre navigateur :
```
https://streamyzstorage.blob.core.windows.net/livespasses?restype=container&comp=list&sp=racwdl&st=2025-08-05T16:30:12Z&se=2025-09-30T00:45:12Z&sv=2024-11-04&sr=c&sig=Vu%2BjnQg8vv3VebczR0Lb2mm4p75X%2FwfFO2jzSIS%2BPVk%3D
```

**Résultat attendu :**
```xml
<?xml version="1.0" encoding="utf-8"?>
<EnumerationResults>
  <Blobs />
</EnumerationResults>
```
✅ Si vous voyez ceci = Connexion Azure OK
❌ Si erreur = Token invalide

### 2. **Lancer l'App** (1 minute)
```bash
cd c:\Projects\streamyz
flutter run
```

### 3. **Créer un Live Test** (2 minutes)
1. ✅ Cliquez "Démarrer Live"
2. ✅ Écrivez "Test récap Azure" comme description
3. ✅ Lancez le live
4. ✅ **ATTENDEZ 30 secondes minimum**
5. ✅ Cliquez "Arrêter le live"

### 4. **Vérifier l'Upload** (1 minute)
Dans les logs Flutter, cherchez :
```
✅ Enregistrement sauvegardé sur Azure
☁️ URL: https://streamyzstorage.blob.core.windows.net/livespasses/live_XXX.mp4
```

### 5. **Voir le Récap** (30 secondes)
1. ✅ Allez dans l'onglet "Pour vous"
2. ✅ Cherchez votre live avec badge **"ENREGISTRÉ"**
3. ✅ Cliquez dessus → Le récap s'affiche

## 🔍 Si ça ne marche pas

### Problème 1 : Pas de badge "ENREGISTRÉ"
**Cause :** L'upload Azure a échoué
**Solution :** Vérifiez les logs pour voir l'erreur d'upload

### Problème 2 : Live visible mais pas de récap
**Cause :** Fichier uploadé mais pas accessible
**Solution :** Re-testez l'URL de connexion Azure

### Problème 3 : Erreur dans les logs
**Cause :** Permissions ou token expiré
**Solution :** Le token expire le **6 août à 00:34**, générez-en un nouveau

## 🛠️ Diagnostic Avancé

Si les tests rapides ne marchent pas, ajoutez cette page à votre app pour un diagnostic approfondi :

### Dans votre `main.dart` ou navigation :
```dart
import 'package:streamyz/screens/azure_diagnostic_page.dart';

// Ajouter cette route
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AzureDiagnosticPage()),
);
```

Cette page vous donnera des diagnostics détaillés en temps réel.

## ⏰ Expiration Imminente

**ATTENTION** : Votre token expire dans **56 jours** (30 septembre 00:45).

**Action recommandée :**
1. ✅ Testez MAINTENANT avec ce token (valide jusqu'au 30 septembre)
2. ✅ Le token a maintenant une durée suffisante pour vos tests
3. ✅ Plus besoin de mettre à jour avant expiration pendant 2 mois

## 🎯 Objectif

À la fin de ce test de 5 minutes, vous devriez :
- ✅ Voir vos lives dans "Pour vous"
- ✅ Badge "ENREGISTRÉ" visible
- ✅ Récap accessible en cliquant
- ✅ Fichiers visibles sur Azure

**Si l'un de ces éléments manque, utilisez le guide de diagnostic complet !**
