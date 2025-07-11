# Fix Firestore Index pour les Gifts

## Problème
L'app rencontre une erreur d'index manquant pour les requêtes sur la collection `gifts` :

```
Query(gifts where liveID==live_C5m4mvOLKZScaUVAXkGG223Q1uA3 order by -timestamp, -__name__)
```

## Solution

### Étape 1 : Créer l'index dans Firebase Console
1. Aller sur [Firebase Console](https://console.firebase.google.com/project/streamyz-12c4d/firestore/indexes)
2. Cliquer sur "Create Index"
3. Configurer l'index composite :
   - **Collection ID**: `gifts`
   - **Fields to index**:
     - `liveID` : Ascending
     - `timestamp` : Descending
     - `__name__` : Descending

### Étape 2 : Alternative - Modifier la requête
Si vous ne voulez pas créer d'index, modifier la requête dans le code pour enlever l'orderBy :

```dart
// Au lieu de :
.orderBy('timestamp', descending: true)

// Utiliser :
.limit(50) // et trier en mémoire si nécessaire
```

### Étape 3 : Attendre la création de l'index
Les index Firestore peuvent prendre quelques minutes à être créés. Une fois créé, l'erreur disparaîtra.

## Statut
- [ ] Index créé dans Firebase Console
- [ ] Erreur résolue dans les logs
- [ ] Tests effectués sur l'app

Date de création : 11/07/2025
