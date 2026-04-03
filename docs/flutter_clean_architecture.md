# Camrlex Flutter Clean Architecture

## Objectif

Construire une application Flutter serieuse et evolutive avec trois couches:

1. Presentation
2. Domain
3. Data

Cette separation aide a faire evoluer l app sans melanger UI, logique metier et acces aux donnees.

## Stack retenue

Choix officiel pour Camrlex:

- Flutter
- Riverpod
- GoRouter
- Dio
- Freezed
- Json Serializable
- Firebase Messaging
- image_picker
- file_picker

Backend consomme par l app:

- Django
- PostgreSQL
- JWT auth
- stockage fichiers S3 ou Cloudinary
- admin panel web

Conclusion:

- Riverpod est retenu pour la gestion d etat
- GoRouter est retenu pour la navigation
- Dio est retenu pour les appels API et les interceptors JWT

## Couches

### 1. Presentation

Contient:

- pages
- widgets
- state management
- routing

Responsabilites:

- afficher les ecrans
- declencher les use cases
- gerer les etats de chargement, succes et erreur

### 2. Domain

Contient:

- entities
- use cases
- repository contracts

Responsabilites:

- decrire le metier
- garder une logique independante de Flutter et de l API

### 3. Data

Contient:

- models
- datasources
- repository implementations
- API services

Responsabilites:

- appeler l API
- parser les reponses JSON
- gerer cache local et remote

## Structure recommandee

```text
lib/
  app/
    app.dart
    router/
    theme/
  core/
    constants/
    error/
    network/
    storage/
    utils/
    widgets/
  features/
    auth/
      presentation/
        pages/
        widgets/
        controllers/
      domain/
        entities/
        repositories/
        usecases/
      data/
        models/
        datasources/
        repositories/
    users/
      presentation/
      domain/
      data/
    professionals/
      presentation/
      domain/
      data/
    services/
      presentation/
      domain/
      data/
    feed_search/
      presentation/
      domain/
      data/
    booking/
      presentation/
      domain/
      data/
    payments/
      presentation/
      domain/
      data/
    messaging/
      presentation/
      domain/
      data/
    reviews/
      presentation/
      domain/
      data/
    notifications/
      presentation/
      domain/
      data/
    admin/
      presentation/
      domain/
      data/
```

## State management recommande

Choix retenu:

- Riverpod pour le mobile client et professionnel

Usage recommande:

- `ProviderScope` a la racine de l application
- `AsyncNotifier` ou `Notifier` pour les workflows metier
- providers par feature et par ecran
- separation entre providers presentation et use cases domain

## Navigation recommande

Utiliser `GoRouter` avec:

- routes publiques
- routes client
- routes professionnel
- routes admin ou backoffice separe

Exemples:

- `/auth/login`
- `/auth/register`
- `/client/home`
- `/client/bookings`
- `/client/chat/:conversationId`
- `/pro/dashboard`
- `/pro/services`
- `/pro/availability`
- `/admin/verifications`

Bonnes pratiques:

- redirections par role et statut d authentification
- `ShellRoute` pour les onglets client et professionnel
- guard pour bloquer les routes pro non verifiees

## Gestion reseau et erreurs

Package retenu:

- `Dio`

Prevoir:

- une instance `Dio` unique
- un interceptor auth
- un interceptor refresh token
- mapping d erreurs API vers erreurs domaine
- gestion offline minimale pour cache et retry

## Modeles et code generation

Packages retenus:

- `freezed_annotation`
- `freezed`
- `json_annotation`
- `json_serializable`
- `build_runner`

Usage recommande:

- Freezed pour les entities immuables et les state classes
- Json Serializable pour `fromJson` et `toJson`
- generation via `build_runner`

Commandes utiles:

```bash
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs
```

## Media, fichiers et notifications

Packages retenus:

- `firebase_messaging`
- `image_picker`
- `file_picker`

Usages prevus:

- notifications push pour reservations, paiements, verification et messages
- upload de CNI, diplome, portrait et photo entiere
- envoi de pieces jointes et documents dans la messagerie

## Conventions de repositories

Le domain declare les contrats:

- `AuthRepository`
- `BookingRepository`
- `MessagingRepository`

Le data les implemente:

- `AuthRepositoryImpl`
- `BookingRepositoryImpl`
- `MessagingRepositoryImpl`

## Strategie de livraison

### Phase 1

- Auth
- Professionals
- Services
- Feed and Search
- Booking

### Phase 2

- Payments
- Messaging
- Notifications
- Reviews

### Phase 3

- Admin complet
- analytics
- moderation avancee
