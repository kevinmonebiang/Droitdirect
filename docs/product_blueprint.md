# Camrlex Product Blueprint

## Vision

Camrlex est une application camerounaise de mise en relation entre clients et professionnels du droit:

- avocats
- huissiers
- notaires

Le produit permet de rechercher un professionnel fiable, comprendre ses honoraires, reserver un service juridique, payer, discuter, envoyer des documents et suivre le statut du rendez-vous.

## Roles

### Utilisateur simple

Peut:

- creer un compte
- se connecter
- rechercher des professionnels
- consulter le feed des offres
- filtrer par ville, metier, prix, note et verification
- reserver un service en presentiel ou en ligne
- payer ou confirmer sa reservation
- chatter avec le professionnel
- envoyer des documents
- suivre les statuts de rendez-vous
- recevoir des notifications
- laisser un avis
- signaler un probleme

### Professionnel

Sous-types:

- avocat
- huissier
- notaire

Peut:

- creer un compte professionnel
- completer son profil
- soumettre ses justificatifs
- publier des offres de services
- fixer ses honoraires
- gerer ses disponibilites
- accepter ou refuser des reservations
- chatter avec les clients
- faire des consultations en ligne
- suivre ses revenus et statistiques
- consulter sa progression de verification

### Administrateur

Peut:

- verifier les professionnels
- controler les documents
- valider ou rejeter les comptes
- moderer profils, offres, avis et contenus
- gerer categories, villes et types de services
- suivre litiges, paiements, commissions et signalements

## Regles metier

### Verification professionnelle

Documents de verification:

- CNI
- numero du barreau ou identifiant professionnel
- diplome
- photo entiere
- selfie ou portrait
- attestation d exercice optionnelle

Statuts:

- Brouillon
- Soumis
- En cours d examen
- Verifie
- Rejete
- A completer
- Suspendu

Regle centrale:

Le professionnel peut creer son compte avant verification, mais il ne peut recevoir de reservations qu apres validation administrateur.

### Reservation

Types:

- presentiel
- en ligne

Statuts:

- En attente
- Acceptee
- Refusee
- Annulee
- Terminee
- Expiree
- Litige

### Messagerie

Fonctions:

- texte
- pieces jointes
- images
- statut lu ou non lu
- notifications push

Usages:

- poser des questions avant reservation
- envoyer des documents
- suivre les details du rendez-vous

### Avis et notation

Apres un rendez-vous termine, l utilisateur peut:

- mettre une note sur 5
- ecrire un commentaire
- signaler un probleme

## Parcours utilisateur

### Parcours client

1. Inscription ou connexion
2. Accueil
3. Recherche d un professionnel ou d un service
4. Consultation du profil
5. Choix du type de rendez-vous
6. Choix du creneau
7. Paiement ou confirmation
8. Discussion eventuelle
9. Rendez-vous
10. Avis

### Parcours professionnel

1. Inscription professionnelle
2. Choix du type de metier
3. Creation du profil
4. Soumission des documents
5. Validation admin
6. Publication des offres
7. Reception de reservations
8. Gestion de l agenda
9. Consultation ou prestation
10. Historique et revenus

### Parcours admin

1. Connexion admin
2. Voir les nouvelles demandes de verification
3. Controler les documents
4. Valider ou rejeter
5. Moderer profils et offres
6. Gerer litiges et signalements

## Ecrans de l application

### Partie publique et utilisateur

- Splash screen
- Onboarding
- Choix du role
- Connexion
- Inscription
- Mot de passe oublie
- Accueil
- Recherche
- Resultats
- Detail professionnel
- Detail service
- Reservation
- Paiement
- Mes rendez-vous
- Chat
- Notifications
- Profil utilisateur
- Parametres
- Avis et historique

### Partie professionnelle

- Connexion pro
- Inscription pro
- Selection metier
- Creation profil
- Upload documents
- Statut de verification
- Dashboard pro
- Mes services
- Ajouter un service
- Modifier service
- Agenda et disponibilites
- Reservations recues
- Detail reservation
- Chat
- Revenus
- Parametres professionnels

### Partie admin

Le meilleur choix est un backoffice web separe.

Ecrans admin:

- tableau de bord
- liste professionnels
- validation documents
- gestion reservations
- gestion signalements
- gestion categories
- gestion paiements

## Proposition technique pour la suite

### Frontend mobile

- Flutter
- Riverpod
- GoRouter
- Dio
- Freezed
- Json Serializable
- Firebase Messaging
- image_picker
- file_picker

### Backend retenu

- Django
- PostgreSQL
- JWT auth
- stockage fichiers S3 ou Cloudinary
- admin panel web

Pourquoi:

- mieux adapte a un produit structure et professionnel
- plus solide pour verification, paiements, moderation et reporting
- bonne base pour une evolution ERP plus tard

### Integrations futures

- Orange Money
- MTN MoMo
- WhatsApp ou Google Meet
- geolocalisation
- moderation automatisee

## UX recommandee

L application doit inspirer:

- confiance
- professionnalisme
- clarte
- securite

Palette recommandee:

- bleu fonce
- blanc
- dore discret
- gris clair

## Priorites produit

### MVP

- auth client et professionnel
- verification professionnelle
- profil professionnel
- publication d offres
- feed avec filtres de base
- reservation simple
- chat de base
- notifications de base
- backoffice admin minimal

### Phase 2

- paiement integre
- agenda avance
- avis et notation
- rappels automatiques
- disponibilites dynamiques

### Phase 3

- litiges
- commissions plateforme
- analytics admin
- matching intelligent
