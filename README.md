# VoltWatch - Architecture de l'Application

## Vue d'ensemble
Application mobile Flutter de suivi de consommation électrique avec authentification Supabase, tableau de bord en temps réel, système d'alertes et intégration de paiement.

## Fonctionnalités Principales

### 1. Authentification & Profil Utilisateur
- Connexion multi-méthodes (email, téléphone, identifiant ENEO)
- Récupération mot de passe via SMS/email
- Profil utilisateur avec données ENEO
- Gestion des contrats et historique

### 2. Tableau de Bord & Consommation
- Affichage temps réel de la consommation (kWh)
- Graphiques interactifs (jour/semaine/mois)
- Comparaison avec moyennes locales
- Métriques de performance énergétique

### 3. Alertes & Notifications
- Alertes dépenses anormales (+20%)
- Seuils personnalisés (ex: 50,000 FCFA)
- Notifications rappels de factures
- Alertes coupures programmées

### 4. Paiement & Facturation
- Visualisation factures PDF/HTML
- Intégration Mobile Money & cartes bancaires
- Historique des paiements
- Suivi des échéances

## Architecture Technique

### Structure des Dossiers
```
lib/
├── main.dart
├── theme.dart
├── models/
│   ├── user_model.dart
│   ├── consumption_model.dart
│   ├── bill_model.dart
│   └── alert_model.dart
├── services/
│   ├── supabase_service.dart
│   ├── auth_service.dart
│   └── notification_service.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── bills/
│       └── bills_screen.dart
└── widgets/
    ├── consumption_chart.dart
    ├── alert_card.dart
    └── bill_item.dart
```

### Modèles de Données

#### User Model
- id, email, phone, eneo_client_id
- meter_address, contracts_history
- alert_preferences, spending_limits

#### Consumption Model
- timestamp, kwh_consumed, cost_fcfa
- period_type (daily/weekly/monthly)
- local_average_comparison

#### Bill Model
- id, amount, due_date, status
- pdf_url, payment_history
- late_fees, connection_status

#### Alert Model
- type, threshold, message, is_active
- trigger_conditions, notification_sent

### Services

#### Supabase Service
- Configuration client Supabase
- Gestion base de données temps réel
- Authentification et sécurité

#### Auth Service
- Multi-authentification (email/phone/ENEO)
- Gestion sessions utilisateur
- Récupération mot de passe

#### Notification Service
- Notifications push locales
- Alertes personnalisées
- Rappels automatiques

## Interface Utilisateur

### Écrans Principaux

1. **Login/Register Screen**
   - Champs multi-authentification
   - Validation formulaires
   - Récupération mot de passe

2. **Dashboard Screen**
   - Consommation temps réel
   - Graphiques interactifs
   - Alertes actives
   - Navigation rapide

3. **Profile Screen**
   - Informations utilisateur
   - Paramètres d'alertes
   - Historique contrats
   - Préférences

4. **Bills Screen**
   - Liste factures
   - Détails paiements
   - Options paiement
   - Historique

### Composants Réutilisables

- **ConsumptionChart**: Graphiques avec FL Chart
- **AlertCard**: Cartes d'alertes personnalisées
- **BillItem**: Items de factures avec actions
- **CustomTextField**: Champs de saisie stylisés

## Intégration Backend

### Base de Données Supabase
- Tables: users, consumption_readings, bills, alerts
- Politiques RLS (Row Level Security)
- Triggers pour alertes automatiques
- Réplication temps réel

### Authentification
- Multi-provider (email, phone, magic links)
- JWT tokens avec refresh
- Policies basées sur user_id

## Plan d'Implémentation

### Phase 1: Setup & Authentification
1. Configuration Supabase
2. Modèles de données
3. Service d'authentification
4. Écrans login/register

### Phase 2: Dashboard Principal
1. Service de données temps réel
2. Composants graphiques
3. Écran tableau de bord
4. Navigation principale

### Phase 3: Système d'Alertes
1. Service de notifications
2. Composants d'alertes
3. Configuration utilisateur
4. Tests alertes

### Phase 4: Gestion Factures
1. Service de facturation
2. Écrans factures
3. Intégration paiement
4. Historique

### Phase 5: Finalisation
1. Tests complets
2. Optimisations performance
3. Design polish
4. Déploiement

## Technologies
- **Frontend**: Flutter 3.6+ avec Material 3
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **Charts**: FL Chart pour graphiques
- **State Management**: StatefulWidget + FutureBuilder
- **Notifications**: flutter_local_notifications
- **Stockage**: SharedPreferences pour cache local

## Considérations de Sécurité
- Chiffrement données sensibles
- Validation côté client et serveur  
- Authentification multi-facteurs
- Audit logs pour paiements
- Politiques de confidentialité RGPD
