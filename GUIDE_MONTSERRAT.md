# 🎨 Guide d'Utilisation de Montserrat dans Streamyz

## 📋 Table des Matières
- [🚀 Installation](#-installation)
- [⚙️ Configuration](#️-configuration)
- [🎯 Utilisation](#-utilisation)
- [📱 Exemples Pratiques](#-exemples-pratiques)
- [💡 Bonnes Pratiques](#-bonnes-pratiques)
- [🔧 Styles Prédéfinis](#-styles-prédéfinis)

---

## 🚀 Installation

### **1. Dépendance ajoutée :**
```yaml
# pubspec.yaml
dependencies:
  google_fonts: ^6.1.0
```

### **2. Import nécessaire :**
```dart
import 'package:google_fonts/google_fonts.dart';
```

---

## ⚙️ Configuration

### **Configuration Globale (main.dart)**
La police Montserrat est configurée automatiquement pour toute l'application :

```dart
// Configuration dans MaterialApp
theme: ThemeData.light().copyWith(
  useMaterial3: true,
  textTheme: GoogleFonts.montserratTextTheme(
    Theme.of(context).textTheme,
  ),
  // ... autres configurations
),
darkTheme: ThemeData.dark().copyWith(
  useMaterial3: true,
  textTheme: GoogleFonts.montserratTextTheme(
    ThemeData.dark().textTheme,
  ),
  // ... autres configurations
),
```

### **Avantages de cette approche :**
- ✅ **Application automatique** : Tous les widgets utilisent Montserrat par défaut
- ✅ **Cohérence** : Police uniforme dans toute l'app
- ✅ **Mode sombre/clair** : Adaptée aux deux thèmes
- ✅ **Performance** : Chargement optimisé par Google Fonts

---

## 🎯 Utilisation

### **1. Utilisation Basique**
```dart
Text(
  'Mon texte',
  style: GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
)
```

### **2. Avec Paramètres Avancés**
```dart
Text(
  'Titre Important',
  style: GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.deepPurple,
    letterSpacing: 0.5,
    height: 1.2,
  ),
)
```

### **3. Hériter du Thème + Personnalisation**
```dart
Text(
  'Texte personnalisé',
  style: GoogleFonts.montserrat().copyWith(
    color: Colors.red,
    fontWeight: FontWeight.bold,
  ),
)
```

---

## 📱 Exemples Pratiques

### **🎥 Interface Live Streaming**

#### **Titre du Live :**
```dart
Text(
  'Mon super live gaming !',
  style: GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
)
```

#### **Badge EN DIRECT :**
```dart
Text(
  'EN DIRECT',
  style: GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 1.2,
  ),
)
```

#### **Nom du Host :**
```dart
Text(
  'par StreamyzUser',
  style: GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  ),
)
```

### **💬 Interface Chat**

#### **Messages Chat :**
```dart
Text(
  'Salut tout le monde ! 👋',
  style: GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  ),
)
```

#### **Nom d'Utilisateur :**
```dart
Text(
  'StreamyzUser',
  style: GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.deepPurple,
  ),
)
```

### **📊 Statistiques Live**

#### **Valeurs Numériques :**
```dart
Text(
  '1.2K',
  style: GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.green,
  ),
)
```

#### **Labels Statistiques :**
```dart
Text(
  'Spectateurs',
  style: GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.grey[600],
  ),
)
```

### **🎯 Boutons et Actions**

#### **Boutons Principaux :**
```dart
Text(
  'Démarrer Live',
  style: GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
)
```

#### **Boutons Secondaires :**
```dart
Text(
  'J\'aime',
  style: GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.deepPurple,
  ),
)
```

---

## 💡 Bonnes Pratiques

### **📏 Tailles de Police Recommandées**

| **Usage** | **Taille** | **Poids** | **Exemple** |
|-----------|------------|-----------|-------------|
| **Grands Titres** | 24-28px | w700+ | Titres de pages |
| **Titres Sections** | 18-22px | w600 | Sections importantes |
| **Texte Principal** | 16px | w400-w500 | Corps de texte |
| **Texte Secondaire** | 14px | w400 | Descriptions |
| **Petits Textes** | 12px | w300-w500 | Labels, détails |

### **⚖️ Poids de Police (FontWeight)**

| **Poids** | **Usage** | **Exemple** |
|-----------|-----------|-------------|
| **w300** | Texte très léger | Sous-titres discrets |
| **w400** | Texte normal | Messages chat, descriptions |
| **w500** | Texte important | Noms d'utilisateur, labels |
| **w600** | Éléments proéminents | Titres de sections, boutons |
| **w700** | Très important | Statistiques, badges |
| **w800+** | Maximum impact | Call-to-action principaux |

### **🎨 Couleurs et Contrastes**

#### **Texte Principal :**
- `Colors.grey[900]` (mode clair)
- `Colors.white` (mode sombre)

#### **Texte Secondaire :**
- `Colors.grey[600]` (mode clair)
- `Colors.grey[300]` (mode sombre)

#### **Texte de Marque :**
- `Colors.deepPurple` (accent Streamyz)

---

## 🔧 Styles Prédéfinis

Pour faciliter l'utilisation, des styles prédéfinis sont disponibles dans `MontserratStyles` :

### **Import :**
```dart
import 'package:streamyz/widgets/montserrat_examples.dart';
```

### **Utilisation :**
```dart
// Titres
Text('Mon Titre', style: MontserratStyles.heading1)
Text('Sous-titre', style: MontserratStyles.heading2)
Text('Section', style: MontserratStyles.heading3)

// Corps de texte
Text('Texte principal', style: MontserratStyles.bodyLarge)
Text('Texte normal', style: MontserratStyles.bodyMedium)
Text('Petit texte', style: MontserratStyles.bodySmall)

// Boutons
Text('Bouton Principal', style: MontserratStyles.buttonPrimary)
Text('Bouton Secondaire', style: MontserratStyles.buttonSecondary)

// Chat
Text('Message', style: MontserratStyles.chatMessage)
Text('Utilisateur', style: MontserratStyles.chatUsername)

// Statistiques
Text('1.2K', style: MontserratStyles.statValue)
Text('Spectateurs', style: MontserratStyles.statLabel)

// Live streaming
Text('Titre Live', style: MontserratStyles.liveTitle)
Text('Host', style: MontserratStyles.liveHost)
Text('EN DIRECT', style: MontserratStyles.liveStatus)
```

---

## 🚀 Commandes Utiles

### **Installation des dépendances :**
```bash
flutter pub get
```

### **Voir l'exemple Montserrat :**
```dart
// Ajouter dans une route pour tester
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MontserratExamples(),
  ),
)
```

### **Cache Google Fonts (optionnel) :**
```bash
# Pour de meilleures performances en production
flutter build apk --release
```

---

## ✨ Résultats Attendus

### **Avant (police système) :**
- ❌ Incohérence entre plateformes
- ❌ Look générique
- ❌ Pas de personnalité visuelle

### **Après (Montserrat) :**
- ✅ **Cohérence** : Même rendu sur Android/iOS
- ✅ **Modernité** : Design professionnel et épuré
- ✅ **Lisibilité** : Excellente lisibilité sur mobile
- ✅ **Personnalité** : Identité visuelle Streamyz forte

---

## 🔍 Dépannage

### **Police ne s'affiche pas :**
1. Vérifier la connexion internet (Google Fonts)
2. Relancer l'app : `flutter run`
3. Nettoyer le build : `flutter clean && flutter pub get`

### **Performance :**
- Les polices Google Fonts sont mises en cache automatiquement
- Première utilisation = téléchargement
- Utilisations suivantes = cache local

---

**🎉 Votre application Streamyz utilise maintenant la police Montserrat pour une expérience utilisateur moderne et cohérente !** 