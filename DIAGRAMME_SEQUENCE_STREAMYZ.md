# 🔄 Diagrammes de Séquence - Application Streamyz

## 📋 Description
Ce document présente les diagrammes de séquence **simplifiés** pour les cas d'utilisation "Création et démarrage d'un live" et "Rejoindre un live" avec leurs flux principaux.

---

## 🎥 Diagramme de Séquence : Création et Démarrage d'un Live

### 🎯 Flux Principal Simplifié

```plantuml
@startuml Creation_Live_Simplifie

!theme plain
skinparam sequenceArrowThickness 2
skinparam roundcorner 20

title 🎥 Création et Démarrage d'un Live - Version Simplifiée

actor "👤 HOST" as HOST
participant "📱 Interface" as UI
participant "🎛️ Système" as SYS
participant "🗄️ Base de Données" as DB
participant "📡 ZegoCloud" as ZEGO

HOST -> UI : 1. Ouvrir "Démarrer Live"
HOST -> UI : 2. Saisir titre et description
UI -> SYS : 3. Valider les données
activate SYS

alt Données valides
    SYS -> SYS : Vérifier permissions
    SYS -> DB : Créer le live
    activate DB
    DB -> SYS : Live créé ✅
    deactivate DB
    
    SYS -> ZEGO : Initialiser session streaming
    activate ZEGO
    ZEGO -> SYS : Session prête ✅
    deactivate ZEGO
    
    SYS -> SYS : Démarrer enregistrement
    SYS -> UI : Live prêt
    deactivate SYS
    UI -> HOST : 🎥 Interface de diffusion
    
else Erreur
    SYS -> UI : Afficher erreur
    deactivate SYS
    UI -> HOST : ⚠️ Message d'erreur
end

@enduml
```



---

## 👥 Diagramme de Séquence : Rejoindre un Live

### 🎯 Flux Principal Simplifié

```plantuml
@startuml Rejoindre_Live_Simplifie

!theme plain
skinparam sequenceArrowThickness 2
skinparam roundcorner 20

title 👥 Rejoindre un Live - Version Simplifiée

actor "👥 AUDIENCE" as USER
participant "📱 Interface" as UI
participant "🎛️ Système" as SYS
participant "🗄️ Base de Données" as DB
participant "📡 ZegoCloud" as ZEGO

USER -> UI : 1. Voir liste des lives
UI -> SYS : Charger lives actifs
activate SYS
SYS -> DB : Récupérer lives disponibles
activate DB
DB -> SYS : Liste des lives
deactivate DB

alt Lives disponibles
    SYS -> UI : Afficher les lives
    deactivate SYS
    UI -> USER : 📺 Liste des lives actifs
    
    USER -> UI : 2. Sélectionner un live
    UI -> SYS : Rejoindre le live
    activate SYS
    
    SYS -> DB : Vérifier live actif
    activate DB
    DB -> SYS : Live disponible ✅
    deactivate DB
    
    SYS -> ZEGO : Se connecter au stream
    activate ZEGO
    ZEGO -> SYS : Connexion établie ✅
    deactivate ZEGO
    
    SYS -> DB : Mettre à jour spectateurs (+1)
    activate DB
    deactivate DB
    
    SYS -> UI : Connexion réussie
    deactivate SYS
    UI -> USER : 🎥 Stream + Chat + Interactions
    
else Aucun live
    SYS -> UI : Aucun live actif
    deactivate SYS
    UI -> USER : 📭 "Aucun live en cours"
end

@enduml
```



---

## 📊 Analyse des Diagrammes de Séquence Simplifiés

### **🎥 Création et Démarrage d'un Live**

| **Élément** | **Description** | **Rôle** |
|-------------|-----------------|----------|
| **Participants** | HOST, Interface, Système, Base de Données, ZegoCloud | 5 acteurs principaux |
| **Flux principal** | Saisie → Validation → Création → Streaming → Activation | Processus avec streaming |
| **Gestion d'erreur** | Alternative intégrée avec `alt/else` | Gestion directe des échecs |
| **Points critiques** | Validation données, Permissions, Session ZegoCloud | 3 points de contrôle |

### **👥 Rejoindre un Live**

| **Élément** | **Description** | **Rôle** |
|-------------|-----------------|----------|
| **Participants** | AUDIENCE, Interface, Système, Base de Données, ZegoCloud | 5 acteurs principaux |
| **Flux principal** | Navigation → Sélection → Connexion ZegoCloud → Affichage | Processus avec streaming |
| **Gestion d'erreur** | Alternative pour absence de live | Cas d'échec principal |
| **Points critiques** | Disponibilité lives, Connexion ZegoCloud, Mise à jour stats | 3 points de contrôle |

---

## 🔗 Interactions Système Simplifiées

### **📡 Composants Principaux**
- **Interface** : Interaction avec l'utilisateur
- **Système** : Logique métier et contrôles
- **Base de Données** : Stockage et récupération des données
- **ZegoCloud** : Service de streaming temps réel WebRTC

### **🔄 Flux Simplifiés**
- **Création Live** : HOST → Interface → Système → Base de données → ZegoCloud
- **Rejoindre Live** : AUDIENCE → Interface → Système → Base de données → ZegoCloud

### **⚡ Points de Contrôle**
- **Validation des données** (titre, description)
- **Vérification des permissions** (caméra, micro)
- **Contrôle de disponibilité** des lives
- **Connexion streaming** ZegoCloud (WebRTC)

---

## 🛠️ Instructions d'Utilisation

### **Pour PlantUML :**
1. Copier l'un des codes PlantUML ci-dessus
2. Le coller dans [plantuml.com](http://plantuml.com/plantuml)
3. Ou utiliser l'extension PlantUML dans VS Code

### **Avantages de la Version Simplifiée :**
- **Lisibilité maximale** : Diagrammes épurés et faciles à comprendre
- **Focus sur l'essentiel** : Flux principaux sans complexité inutile
- **Compréhension rapide** : Vision claire des interactions principales
- **Maintenance facilitée** : Documentation concise et à jour

Ces diagrammes de séquence simplifiés offrent une **vision claire et directe** des fonctionnalités principales de Streamyz ! 