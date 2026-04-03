# DroitDirect Backend

Backend Django REST Framework de DroitDirect.

## Stack

- Django
- Django REST Framework
- Simple JWT
- PostgreSQL
- media local en developpement

## Demarrage

```powershell
cd C:\Users\Crack_\Documents\camrlex\backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

## Base de donnees

- PostgreSQL est la cible principale
- les migrations initiales sont deja generees
- le projet contient aussi les migrations du flux de reservation enrichi

## Modules disponibles

- `accounts`
- `professionals`
- `services`
- `bookings`
- `payments`
- `messaging`
- `notifications_app`
- `reviews`
- `taxonomy`

## Endpoints principaux

### Auth

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/verify-otp`
- `POST /api/auth/logout`
- `POST /api/auth/refresh`

### Profil utilisateur

- `GET /api/me`
- `PATCH /api/me`

### Professionnels

- `GET /api/professionals`
- `POST /api/professionals`
- `GET /api/professionals/me`
- `PUT /api/professionals/{id}`
- `PATCH /api/professionals/{id}`
- `POST /api/professionals/{id}/verification`

### Services

- `GET /api/services`
- `POST /api/services`
- `GET /api/services/{id}`
- `PUT /api/services/{id}`
- `DELETE /api/services/{id}`

### Reservations

- `GET /api/bookings`
- `POST /api/bookings`
- `PUT /api/bookings/{id}/accept`
- `PUT /api/bookings/{id}/reject`
- `PUT /api/bookings/{id}/cancel`
- `PUT /api/bookings/{id}/complete`

Les reservations transportent maintenant:

- `issue_title`
- `issue_summary`
- `note`

### Paiements

- `POST /api/payments/initiate`
- `POST /api/payments/confirm`
- `GET /api/payments/{id}`

Codes USSD utilises:

- Orange Money: `#150*46*0780539*{amount}*2#`
- MTN Mobile Money: `*126*4*752923*{amount}#`

### Messagerie

- `GET /api/conversations`
- `POST /api/conversations/{id}/mark_read`
- `POST /api/messages`

### Notifications

- `GET /api/notifications`
- `POST /api/notifications/{id}/read`

### Admin

- `GET /api/admin/overview`

## Regles metier importantes

- seuls les clients peuvent creer une reservation
- seuls les professionnels verifies peuvent recevoir des reservations
- le professionnel recoit une notification a la creation d'une reservation
- le client recoit une notification apres acceptation ou refus
- le paiement n'est possible qu'apres acceptation
- la messagerie ne doit pas remplacer la notification de demande initiale
- l'admin peut consulter les documents soumis avant validation du compte

## Verifications utiles

```powershell
cd C:\Users\Crack_\Documents\camrlex\backend
python manage.py check
python -m compileall backend
