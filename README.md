# DroitDirect

Application camerounaise de reservation de services juridiques ( Avocat, huissiers, notaires,)

## Ce qui fonctionne

- Connexion et inscription `client` et `professionnel`
- Acces admin prive separe de l'entree publique
- Creation et modification du profil client
- Creation et modification du profil professionnel
- Formulaires professionnels differents pour `avocat`, `huissier` et `notaire`
- Upload de photo de profil et de documents de verification
- Publication d'offres de services depuis le compte professionnel
- Feed des services avec profils professionnels reels
- Reservation d'un service avec:
  - mode `en ligne` ou `presentiel`
  - titre du probleme
  - bref resume du probleme
- Reception de la demande par le professionnel dans `Reservations`
- Acceptation ou refus par le professionnel
- Notification in-app au client et au professionnel
- Paiement guide par code USSD:
  - Orange Money
  - MTN Mobile Money
- Messagerie reliee a la reservation
- Console admin pour voir les dossiers soumis et verifier les comptes

## Architecture

- Frontend Flutter dans [lib](C:\Users\Crack_\Documents\camrlex\lib)
- Backend Django REST Framework dans [backend](C:\Users\Crack_\Documents\camrlex\backend)
- Documentation produit dans [product_blueprint.md](C:\Users\Crack_\Documents\camrlex\docs\product_blueprint.md)
- Domaine backend dans [backend_domain_model.md](C:\Users\Crack_\Documents\camrlex\docs\backend_domain_model.md)
- Architecture Flutter dans [flutter_clean_architecture.md](C:\Users\Crack_\Documents\camrlex\docs\flutter_clean_architecture.md)

## Stack

### Frontend

- Flutter
- Riverpod
- GoRouter
- Dio
- Freezed / Json Serializable
- image_picker
- file_picker
- flutter_svg

### Backend

- Django
- Django REST Framework
- Simple JWT
- PostgreSQL
- stockage media local en developpement

## Lancement rapide

### Backend

```powershell
cd C:\Users\Crack_\Documents\camrlex\backend
python manage.py migrate
python manage.py runserver
```

### Frontend

```powershell
cd C:\Users\Crack_\Documents\camrlex
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run -d chrome
```

## Flux reservation

1. Le client choisit un service.
2. Il renseigne le titre de son probleme et un bref resume.
3. Le professionnel recoit une notification et voit la demande dans `Reservations`.
4. Le professionnel accepte ou refuse.
5. Le client recoit une notification.
6. Si la demande est acceptee, le client paie via Orange Money ou MTN.
7. Apres confirmation du paiement, la conversation peut se poursuivre en messagerie.

## Notes importantes

- L'admin ne doit pas etre cree depuis l'inscription publique.
- Les notifications de reservation ouvrent la section `Reservations`.
- Les notifications de message ouvrent la section `Messages`.
- La messagerie est reservee aux vraies conversations liees aux rendez-vous et aux reservations.
