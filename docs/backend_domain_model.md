# Camrlex Backend Domain Model

## Stack backend recommandee

Choix retenu:

- Django
- PostgreSQL
- JWT auth
- stockage fichiers S3 ou Cloudinary
- admin panel web

Pourquoi:

- modele robuste pour un produit juridique et professionnel
- workflows admin solides pour verification et moderation
- excellente base pour reporting, paiements et evolution ERP plus tard

## Modules metiers

### Module 1 - Auth

Responsabilites:

- login
- register
- OTP
- refresh token
- gestion des roles

API a prevoir:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/verify-otp`
- `POST /auth/logout`
- `POST /auth/refresh`

### Module 2 - Users

Responsabilites:

- profil utilisateur
- favoris
- historique

API a prevoir:

- `GET /me`
- `PUT /me`
- `GET /users/bookings`

### Module 3 - Professionals

Responsabilites:

- profil
- verification
- specialites
- statut

API a prevoir:

- `POST /professionals/profile`
- `GET /professionals`
- `GET /professionals/{id}`
- `PUT /professionals/{id}`
- `GET /professionals/{id}/services`

### Module 4 - Verification

Responsabilites:

- soumission des pieces
- suivi du statut
- revue admin

API a prevoir:

- `POST /professionals/{id}/verification`
- `GET /professionals/{id}/verification-status`

### Module 5 - Services

Responsabilites:

- creation
- modification
- suppression
- publication
- categories

API a prevoir:

- `POST /services`
- `GET /services`
- `GET /services/{id}`
- `PUT /services/{id}`
- `DELETE /services/{id}`

### Module 6 - Feed and Search

Responsabilites:

- recherche
- filtres
- tri
- recommandations

API a prevoir:

- `GET /services`
- `GET /professionals`
- endpoints de recherche filtree selon ville, note, prix, specialite et verification

### Module 7 - Booking

Responsabilites:

- agenda
- disponibilite
- reservation
- statut

API a prevoir:

- `POST /bookings`
- `GET /bookings`
- `GET /bookings/{id}`
- `PUT /bookings/{id}/accept`
- `PUT /bookings/{id}/reject`
- `PUT /bookings/{id}/cancel`
- `PUT /bookings/{id}/complete`

### Module 8 - Payments

Responsabilites:

- frais
- acomptes
- commissions plateforme
- remboursements

API a prevoir:

- `POST /payments/initiate`
- `POST /payments/webhook`
- `GET /payments/{id}`

### Module 9 - Messaging

Responsabilites:

- conversations
- fichiers
- notifications

API a prevoir:

- `GET /conversations`
- `POST /messages`

### Module 10 - Reviews

Responsabilites:

- notes
- commentaires
- signalements

API a prevoir:

- `POST /reviews`
- `GET /professionals/{id}/reviews`

### Module 11 - Admin

Responsabilites:

- validation
- moderation
- reporting

API a prevoir:

- endpoints admin de validation
- suspension de compte
- reporting reservations, paiements, signalements

## Entites principales

### User

Fields:

- `id`
- `fullName`
- `phone`
- `email`
- `passwordHash`
- `role`
- `avatar`
- `city`
- `createdAt`
- `updatedAt`
- `status`

### ProfessionalProfile

Fields:

- `id`
- `userId`
- `professionType`
- `bio`
- `city`
- `address`
- `yearsExperience`
- `languages`
- `specialties`
- `officeName`
- `verificationStatus`
- `verifiedAt`
- `ratingAverage`
- `totalReviews`
- `isActive`

### VerificationDocument

Fields:

- `id`
- `professionalId`
- `cniFrontUrl`
- `cniBackUrl`
- `barNumber`
- `diplomaUrl`
- `fullBodyPhotoUrl`
- `portraitPhotoUrl`
- `additionalDocs`
- `status`
- `rejectionReason`
- `reviewedBy`
- `reviewedAt`

### ServiceOffer

Fields:

- `id`
- `professionalId`
- `title`
- `description`
- `categoryId`
- `mode`
- `priceType`
- `amount`
- `currency`
- `durationMinutes`
- `city`
- `address`
- `isPublished`
- `createdAt`

### AvailabilitySlot

Fields:

- `id`
- `professionalId`
- `dayOfWeek`
- `startTime`
- `endTime`
- `isAvailable`
- `slotDuration`

### Booking

Fields:

- `id`
- `userId`
- `professionalId`
- `serviceId`
- `bookingType`
- `appointmentDate`
- `startTime`
- `endTime`
- `amount`
- `status`
- `paymentStatus`
- `meetingLink`
- `onsiteAddress`
- `note`
- `createdAt`

### Payment

Fields:

- `id`
- `bookingId`
- `userId`
- `amount`
- `currency`
- `provider`
- `transactionRef`
- `status`
- `paidAt`

### Conversation

Fields:

- `id`
- `bookingId`
- `userId`
- `professionalId`
- `createdAt`

### Message

Fields:

- `id`
- `conversationId`
- `senderId`
- `messageType`
- `content`
- `attachmentUrl`
- `isRead`
- `createdAt`

### Review

Fields:

- `id`
- `bookingId`
- `userId`
- `professionalId`
- `rating`
- `comment`
- `createdAt`

### Category

Fields:

- `id`
- `name`
- `professionType`
- `isActive`

### Notification

Fields:

- `id`
- `userId`
- `title`
- `body`
- `type`
- `isRead`
- `createdAt`

## Relations cles

- `User 1 -> 0..1 ProfessionalProfile`
- `ProfessionalProfile 1 -> n VerificationDocument`
- `ProfessionalProfile 1 -> n ServiceOffer`
- `ProfessionalProfile 1 -> n AvailabilitySlot`
- `User 1 -> n Booking`
- `ProfessionalProfile 1 -> n Booking`
- `Booking 1 -> 0..1 Payment`
- `Booking 1 -> 0..1 Conversation`
- `Conversation 1 -> n Message`
- `Booking 1 -> 0..1 Review`

## Regles metier importantes

### Verification

- un professionnel non valide ne recoit pas de reservation
- un professionnel valide a un badge verifie

### Reservation

- un creneau deja pris n est plus reservable
- le professionnel peut accepter ou refuser
- si paiement requis, la reservation n est confirmee qu apres paiement

### Avis

- seul un utilisateur ayant termine une reservation peut noter

### Publication

- seuls les professionnels verifies peuvent publier une offre

### Conformite

- l admin peut suspendre un compte
- le signalement par utilisateur doit etre possible

## Recommandations techniques

- utiliser des UUID pour toutes les entites
- ajouter `createdAt` et `updatedAt` partout si possible
- utiliser une suppression logique pour `ServiceOffer`, `User` et `Category`
- separer les statuts de reservation, paiement et verification
- journaliser les actions admin de moderation et de verification
