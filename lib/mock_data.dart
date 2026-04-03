import 'models.dart';

const meNjoyaProfile = ProfessionalProfile(
  fullName: 'Me Njoya Clarisse',
  profession: LegalProfession.avocat,
  professionalNumber: 'BAR-CM-2045',
  verificationStatus: VerificationStatus.verified,
  city: 'Douala',
  interventionZone: 'Douala, Bonanjo, Akwa, Bonapriso',
  languages: ['Francais', 'Anglais'],
  bio: 'Avocate specialisee en droit de la famille et accompagnement des PME.',
  specialties: ['Droit de la famille', 'Mediation', 'PME'],
  yearsExperience: 9,
  officeName: 'Cabinet Njoya & Associes',
  address: 'Bonanjo, Douala',
  averageRating: 4.8,
  reviews: [
    Review(
      authorName: 'Mireille K.',
      rating: 5,
      comment: 'Professionnelle, claire et tres reactive.',
    ),
    Review(
      authorName: 'Wilfried N.',
      rating: 4.5,
      comment: 'Tres bonne consultation en ligne.',
    ),
  ],
  canReceiveBookings: true,
);

const maitreTallaProfile = ProfessionalProfile(
  fullName: 'Maitre Talla Serge',
  profession: LegalProfession.notaire,
  professionalNumber: 'NOT-CM-1188',
  verificationStatus: VerificationStatus.verified,
  city: 'Yaounde',
  interventionZone: 'Yaounde centre et environs',
  languages: ['Francais'],
  bio: 'Notaire pour actes, contrats, authentifications et successions.',
  specialties: ['Actes notaries', 'Contrats', 'Successions'],
  yearsExperience: 14,
  officeName: 'Etude Talla',
  address: 'Centre-ville, Yaounde',
  averageRating: 4.7,
  reviews: [
    Review(
      authorName: 'Arnaud E.',
      rating: 4.5,
      comment: 'Traitement serieux et rapide du dossier.',
    ),
  ],
  canReceiveBookings: true,
);

const ndziProfile = ProfessionalProfile(
  fullName: 'H. Ndzi Hugo',
  profession: LegalProfession.huissier,
  professionalNumber: 'HUI-CM-7742',
  verificationStatus: VerificationStatus.underReview,
  city: 'Bafoussam',
  interventionZone: 'Bafoussam et Ouest',
  languages: ['Francais'],
  bio: 'Huissier intervenant pour constat, recouvrement et significations.',
  specialties: ['Constat', 'Recouvrement', 'Signification'],
  yearsExperience: 6,
  officeName: 'Etude Ndzi',
  address: 'Carrefour Tamdja, Bafoussam',
  averageRating: 4.2,
  reviews: [
    Review(
      authorName: 'Brice S.',
      rating: 4,
      comment: 'Bonne prise en charge, delai respecte.',
    ),
  ],
  canReceiveBookings: false,
);

final List<ServiceOffer> initialOffers = [
  const ServiceOffer(
    id: 'offer-1',
    profile: meNjoyaProfile,
    title: 'Consultation juridique 30 min',
    description:
        'Consultation sur divorce, garde d enfants, pension et mediation.',
    category: 'Consultation',
    mode: ServiceMode.both,
    feeCfa: 25000,
    durationLabel: '30 min',
    requiredDocuments: ['Piece d identite', 'Resume du dossier'],
    executionDelay: 'Sous 24h',
    city: 'Douala',
    instantBooking: true,
    isPublished: true,
  ),
  const ServiceOffer(
    id: 'offer-2',
    profile: maitreTallaProfile,
    title: 'Etablissement d acte notarie',
    description:
        'Preparation, verification et signature d actes notaries pour particuliers et PME.',
    category: 'Acte notarie',
    mode: ServiceMode.inPerson,
    feeCfa: 60000,
    durationLabel: '1h',
    requiredDocuments: ['CNI', 'Projet ou informations du contrat'],
    executionDelay: '48h a 72h',
    city: 'Yaounde',
    instantBooking: false,
    isPublished: true,
  ),
  const ServiceOffer(
    id: 'offer-3',
    profile: ndziProfile,
    title: 'Signification d acte',
    description:
        'Interventions pour constat, recouvrement et signification selon planning.',
    category: 'Huissier',
    mode: ServiceMode.both,
    feeCfa: 40000,
    durationLabel: 'Variable',
    requiredDocuments: ['Copie de l acte', 'Coordonnees du destinataire'],
    executionDelay: '72h',
    city: 'Bafoussam',
    instantBooking: false,
    isPublished: true,
  ),
];

final List<BookingRequest> sampleBookings = [
  const BookingRequest(
    id: 'booking-1',
    clientName: 'Ariane M.',
    serviceTitle: 'Consultation juridique 30 min',
    professionalName: 'Me Njoya Clarisse',
    mode: ServiceMode.online,
    dateLabel: '24 mars 2026 - 10:00',
    priceCfa: 25000,
    status: BookingStatus.accepted,
    paymentStatus: PaymentStatus.pending,
    locationLabel: 'Lien Meet a venir',
    urgency: BookingUrgency.medium,
    createdAt: '2026-03-23T09:20:00',
  ),
  const BookingRequest(
    id: 'booking-2',
    clientName: 'Junior T.',
    serviceTitle: 'Signification d acte',
    professionalName: 'H. Ndzi Hugo',
    mode: ServiceMode.inPerson,
    dateLabel: '26 mars 2026 - 15:30',
    priceCfa: 40000,
    status: BookingStatus.pending,
    paymentStatus: PaymentStatus.pending,
    locationLabel: 'Etude Ndzi, Bafoussam',
    urgency: BookingUrgency.urgent,
    createdAt: '2026-03-23T10:20:00',
    issueTitle: 'Signification urgente',
    issueSummary: 'Le client souhaite une signification rapide avant audience.',
  ),
];

final List<AdminMetric> adminMetrics = const [
  AdminMetric(label: 'Pros a verifier', value: '18'),
  AdminMetric(label: 'Reservations en litige', value: '3'),
  AdminMetric(label: 'Signalements ouverts', value: '5'),
  AdminMetric(label: 'Commissions du mois', value: '1.8M FCFA'),
];

final List<ConversationPreview> sampleConversations = const [
  ConversationPreview(
    id: 'conv-1',
    contactName: 'Me Njoya Clarisse',
    subtitle: 'Documents bien recus, je confirme le creneau.',
    unreadCount: 1,
    lastActivityAt: '2026-03-23T09:20:00',
    messages: [
      ChatMessage(
        senderName: 'Utilisateur Camrlex',
        message:
            'Bonjour Maitre, puis-je envoyer les pieces avant le rendez-vous ?',
        sentAt: '09:10',
        isMine: true,
        isRead: true,
      ),
      ChatMessage(
        senderName: 'Me Njoya Clarisse',
        message: 'Oui, vous pouvez joindre la CNI et le resume du dossier.',
        sentAt: '09:12',
        isMine: false,
        isRead: true,
      ),
      ChatMessage(
        senderName: 'Utilisateur Camrlex',
        message: 'Je vous envoie le dossier en PDF.',
        sentAt: '09:13',
        isMine: true,
        isRead: true,
        attachmentLabel: 'dossier_famille.pdf',
      ),
      ChatMessage(
        senderName: 'Me Njoya Clarisse',
        message: 'Documents bien recus, je confirme le creneau.',
        sentAt: '09:20',
        isMine: false,
        isRead: false,
      ),
    ],
  ),
  ConversationPreview(
    id: 'conv-2',
    contactName: 'Service Support Camrlex',
    subtitle: 'Votre compte est en cours de verification.',
    unreadCount: 0,
    lastActivityAt: '2026-03-22T18:00:00',
    messages: [
      ChatMessage(
        senderName: 'Service Support Camrlex',
        message: 'Votre compte professionnel est en cours d examen.',
        sentAt: 'Hier',
        isMine: false,
        isRead: true,
      ),
    ],
  ),
];

final List<AppNotification> sampleNotifications = const [
  AppNotification(
    id: 'notif-1',
    title: 'Reservation acceptee',
    body: 'Me Njoya Clarisse a accepte votre consultation en ligne.',
    type: 'booking_accepted',
    timeLabel: 'Il y a 5 min',
    isUnread: true,
  ),
  AppNotification(
    id: 'notif-2',
    title: 'Nouveau message',
    body: 'Un nouveau message a ete recu dans votre chat.',
    type: 'message',
    timeLabel: 'Il y a 12 min',
    isUnread: true,
  ),
  AppNotification(
    id: 'notif-3',
    title: 'Paiement confirme',
    body: 'Votre acompte de 25 000 FCFA a ete confirme.',
    type: 'payment_confirmed',
    timeLabel: 'Aujourd hui',
    isUnread: false,
  ),
  AppNotification(
    id: 'notif-4',
    title: 'Compte en examen',
    body: 'Le dossier professionnel est passe en cours d examen.',
    type: 'verification',
    timeLabel: 'Hier',
    isUnread: false,
  ),
];
