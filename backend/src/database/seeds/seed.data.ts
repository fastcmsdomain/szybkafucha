/**
 * Seed Data for Development
 * Test users, contractors, and sample tasks
 */
import { UserType, UserStatus } from '../../users/entities/user.entity';
import {
  KycStatus,
  TaskCategory,
} from '../../contractor/entities/contractor-profile.entity';
import { TaskStatus } from '../../tasks/entities/task.entity';

// Warsaw area coordinates for realistic test data
const WARSAW_CENTER = { lat: 52.2297, lng: 21.0122 };

// Generate random offset for location (within ~5km)
const randomOffset = () => (Math.random() - 0.5) * 0.1;

// Test Clients
export const seedClients = [
  {
    id: '11111111-1111-1111-1111-111111111111',
    types: ['client'], // CHANGED: now array of roles
    phone: '+48111111111',
    email: 'jan.kowalski@test.pl',
    name: 'Jan Kowalski',
    status: UserStatus.ACTIVE,
    avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=jan',
    // Bio moved to client_profiles table
    clientProfile: {
      bio: 'Regularny klient platformy. Cenię terminowość i profesjonalizm.',
    },
  },
  {
    id: '11111111-1111-1111-1111-111111111112',
    types: ['client'], // CHANGED: now array of roles
    phone: '+48111111112',
    email: 'anna.nowak@test.pl',
    name: 'Anna Nowak',
    status: UserStatus.ACTIVE,
    avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=anna',
    // Bio moved to client_profiles table
    clientProfile: {
      bio: 'Pracuję zdalnie, często potrzebuję pomocy z zakupami i odbiorem paczek.',
    },
  },
  {
    id: '11111111-1111-1111-1111-111111111113',
    types: ['client'], // CHANGED: now array of roles
    phone: '+48111111113',
    email: 'piotr.wisniewski@test.pl',
    name: 'Piotr Wiśniewski',
    status: UserStatus.ACTIVE,
    avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=piotr',
    // Bio moved to client_profiles table
    clientProfile: {
      bio: 'Przedsiębiorca, często podróżuję. Szukam rzetelnych wykonawców do różnych zleceń.',
    },
  },
];

// Test Contractors
export const seedContractors = [
  {
    user: {
      id: '22222222-2222-2222-2222-222222222221',
      types: ['contractor'], // CHANGED: now array of roles
      phone: '+48222222221',
      email: 'marek.kurier@test.pl',
      name: 'Marek Szybki',
      status: UserStatus.ACTIVE,
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=marek',
      // Bio moved to contractor_profiles table
    },
    profile: {
      bio: 'Profesjonalny kurier z 5-letnim doświadczeniem. Szybko i bezpiecznie dostarczam paczki w całej Warszawie.',
      categories: [
        TaskCategory.PACZKI,
        TaskCategory.ZAKUPY,
        TaskCategory.KOLEJKI,
      ],
      serviceRadiusKm: 15,
      kycStatus: KycStatus.VERIFIED,
      kycIdVerified: true,
      kycSelfieVerified: true,
      kycBankVerified: true,
      ratingAvg: 4.8,
      ratingCount: 127,
      completedTasksCount: 156,
      isOnline: true,
      lastLocationLat: WARSAW_CENTER.lat + randomOffset(),
      lastLocationLng: WARSAW_CENTER.lng + randomOffset(),
      lastLocationAt: new Date(),
    },
  },
  {
    user: {
      id: '22222222-2222-2222-2222-222222222222',
      types: ['contractor'], // CHANGED: now array of roles
      phone: '+48222222222',
      email: 'tomek.zlotaraczka@test.pl',
      name: 'Tomasz Złota Rączka',
      status: UserStatus.ACTIVE,
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=tomek',
      // Bio moved to contractor_profiles table
    },
    profile: {
      bio: 'Montuję meble IKEA i nie tylko. Mam własne narzędzia. Szybko i solidnie.',
      categories: [TaskCategory.MONTAZ, TaskCategory.PRZEPROWADZKI],
      serviceRadiusKm: 20,
      kycStatus: KycStatus.VERIFIED,
      kycIdVerified: true,
      kycSelfieVerified: true,
      kycBankVerified: true,
      ratingAvg: 4.9,
      ratingCount: 89,
      completedTasksCount: 98,
      isOnline: true,
      lastLocationLat: WARSAW_CENTER.lat + randomOffset(),
      lastLocationLng: WARSAW_CENTER.lng + randomOffset(),
      lastLocationAt: new Date(),
    },
  },
  {
    user: {
      id: '22222222-2222-2222-2222-222222222223',
      types: ['contractor'], // CHANGED: now array of roles
      phone: '+48222222223',
      email: 'kasia.sprzataczka@test.pl',
      name: 'Katarzyna Czyścioch',
      status: UserStatus.ACTIVE,
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=kasia',
      // Bio moved to contractor_profiles table
    },
    profile: {
      bio: 'Profesjonalne sprzątanie mieszkań i biur. Mam własne środki czystości. Terminowo i dokładnie.',
      categories: [TaskCategory.SPRZATANIE],
      serviceRadiusKm: 10,
      kycStatus: KycStatus.VERIFIED,
      kycIdVerified: true,
      kycSelfieVerified: true,
      kycBankVerified: true,
      ratingAvg: 4.7,
      ratingCount: 64,
      completedTasksCount: 72,
      isOnline: false,
      lastLocationLat: WARSAW_CENTER.lat + randomOffset(),
      lastLocationLng: WARSAW_CENTER.lng + randomOffset(),
      lastLocationAt: new Date(Date.now() - 3600000), // 1 hour ago
    },
  },
  {
    user: {
      id: '22222222-2222-2222-2222-222222222224',
      types: ['contractor'], // CHANGED: now array of roles
      phone: '+48222222224',
      email: 'adam.nowy@test.pl',
      name: 'Adam Nowy',
      status: UserStatus.ACTIVE,
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=adam',
      // Bio moved to contractor_profiles table
    },
    profile: {
      bio: 'Nowy na platformie, ale chętny do pracy! Pomogę z zakupami, paczkami i czekaniem w kolejkach.',
      categories: [
        TaskCategory.PACZKI,
        TaskCategory.ZAKUPY,
        TaskCategory.KOLEJKI,
      ],
      serviceRadiusKm: 8,
      kycStatus: KycStatus.PENDING, // Not verified yet
      kycIdVerified: true,
      kycSelfieVerified: false,
      kycBankVerified: false,
      ratingAvg: 0,
      ratingCount: 0,
      completedTasksCount: 0,
      isOnline: true,
      lastLocationLat: WARSAW_CENTER.lat + randomOffset(),
      lastLocationLng: WARSAW_CENTER.lng + randomOffset(),
      lastLocationAt: new Date(),
    },
  },
  // DUAL-ROLE USER: Both client and contractor
  {
    user: {
      id: '44444444-4444-4444-4444-444444444441',
      types: ['client', 'contractor'], // DUAL-ROLE: has both roles
      phone: '+48444444441',
      email: 'dual@test.pl',
      name: 'Michał Dual',
      status: UserStatus.ACTIVE,
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=michal',
    },
    profile: {
      bio: 'Wykonawca z doświadczeniem, który także korzysta z platformy jako klient.',
      categories: [TaskCategory.MONTAZ],
      serviceRadiusKm: 12,
      kycStatus: KycStatus.VERIFIED,
      kycIdVerified: true,
      kycSelfieVerified: true,
      kycBankVerified: true,
      ratingAvg: 4.6,
      ratingCount: 45,
      completedTasksCount: 52,
      isOnline: false,
      lastLocationLat: WARSAW_CENTER.lat + randomOffset(),
      lastLocationLng: WARSAW_CENTER.lng + randomOffset(),
      lastLocationAt: new Date(Date.now() - 7200000), // 2 hours ago
    },
    clientProfile: {
      bio: 'Regularny klient platformy, korzystam z pomocy przy zakupach.',
    },
  },
];

// Sample Tasks in various statuses
export const seedTasks = [
  // Available tasks (status: created)
  {
    id: '33333333-3333-3333-3333-333333333331',
    clientId: seedClients[0].id,
    contractorId: null,
    category: TaskCategory.PACZKI,
    title: 'Odbierz paczkę z paczkomatu',
    description:
      'Paczka jest w paczkomacie przy ul. Marszałkowskiej 100. Kod odbioru: 123456. Proszę dostarczyć pod wskazany adres.',
    locationLat: 52.2297,
    locationLng: 21.0122,
    address: 'ul. Marszałkowska 100, 00-001 Warszawa',
    budgetAmount: 45,
    status: TaskStatus.CREATED,
    scheduledAt: null,
  },
  {
    id: '33333333-3333-3333-3333-333333333332',
    clientId: seedClients[1].id,
    contractorId: null,
    category: TaskCategory.ZAKUPY,
    title: 'Zakupy spożywcze z Biedronki',
    description:
      'Lista zakupów: mleko 2l, chleb, masło, ser żółty, jajka (10 szt), jabłka 1kg. Biedronka przy ul. Puławskiej.',
    locationLat: 52.205,
    locationLng: 21.03,
    address: 'ul. Puławska 45, 02-508 Warszawa',
    budgetAmount: 60,
    status: TaskStatus.CREATED,
    scheduledAt: null,
  },
  {
    id: '33333333-3333-3333-3333-333333333333',
    clientId: seedClients[2].id,
    contractorId: null,
    category: TaskCategory.KOLEJKI,
    title: 'Poczekaj w kolejce w urzędzie',
    description:
      'Urząd Skarbowy Warszawa-Mokotów. Trzeba pobrać numerek i poczekać w kolejce do okienka 5. Dokumenty do złożenia przekażę na miejscu.',
    locationLat: 52.1967,
    locationLng: 21.003,
    address: 'ul. Obrzeżna 5, 02-691 Warszawa',
    budgetAmount: 80,
    status: TaskStatus.CREATED,
    scheduledAt: new Date(Date.now() + 86400000), // Tomorrow
  },

  // Accepted task (contractor assigned, not started)
  {
    id: '33333333-3333-3333-3333-333333333334',
    clientId: seedClients[0].id,
    contractorId: seedContractors[0].user.id,
    category: TaskCategory.PACZKI,
    title: 'Dostawa dokumentów do kancelarii',
    description:
      'Ważne dokumenty do dostarczenia do kancelarii prawnej. Odbiór z mojego biura.',
    locationLat: 52.232,
    locationLng: 21.018,
    address: 'ul. Złota 59, 00-120 Warszawa',
    budgetAmount: 55,
    status: TaskStatus.ACCEPTED,
    acceptedAt: new Date(Date.now() - 1800000), // 30 min ago
    scheduledAt: null,
  },

  // In progress task
  {
    id: '33333333-3333-3333-3333-333333333335',
    clientId: seedClients[1].id,
    contractorId: seedContractors[1].user.id,
    category: TaskCategory.MONTAZ,
    title: 'Montaż szafy IKEA PAX',
    description:
      'Szafa PAX 200x60x236, 4 drzwi przesuwne. Wszystkie elementy są już rozpakowane. Narzędzia po mojej stronie jeśli potrzeba.',
    locationLat: 52.24,
    locationLng: 21.045,
    address: 'ul. Targowa 72/15, 03-734 Warszawa',
    budgetAmount: 200,
    status: TaskStatus.IN_PROGRESS,
    acceptedAt: new Date(Date.now() - 7200000), // 2 hours ago
    startedAt: new Date(Date.now() - 3600000), // 1 hour ago
    scheduledAt: null,
  },

  // Completed task (waiting for confirmation)
  {
    id: '33333333-3333-3333-3333-333333333336',
    clientId: seedClients[2].id,
    contractorId: seedContractors[0].user.id,
    category: TaskCategory.ZAKUPY,
    title: 'Zakupy w aptece',
    description: 'Lista leków na receptę. Receptę przekażę wykonawcy.',
    locationLat: 52.215,
    locationLng: 21.025,
    address: 'ul. Nowy Świat 25, 00-029 Warszawa',
    budgetAmount: 40,
    finalAmount: 40,
    commissionAmount: 4,
    status: TaskStatus.COMPLETED,
    acceptedAt: new Date(Date.now() - 14400000), // 4 hours ago
    startedAt: new Date(Date.now() - 10800000), // 3 hours ago
    completedAt: new Date(Date.now() - 7200000), // 2 hours ago
    completionPhotos: ['https://example.com/proof1.jpg'],
    scheduledAt: null,
  },

  // Cancelled task
  {
    id: '33333333-3333-3333-3333-333333333337',
    clientId: seedClients[0].id,
    contractorId: null,
    category: TaskCategory.SPRZATANIE,
    title: 'Sprzątanie po remoncie',
    description: 'Mieszkanie 50m2, po remoncie. Dużo kurzu i gruzu.',
    locationLat: 52.22,
    locationLng: 21.01,
    address: 'ul. Koszykowa 10/5, 00-564 Warszawa',
    budgetAmount: 250,
    status: TaskStatus.CANCELLED,
    cancelledAt: new Date(Date.now() - 86400000), // Yesterday
    cancellationReason: 'Znalazłem firmę remontową, która posprzątała w cenie.',
    scheduledAt: null,
  },

  // Disputed task
  {
    id: '33333333-3333-3333-3333-333333333338',
    clientId: seedClients[1].id,
    contractorId: seedContractors[2].user.id,
    category: TaskCategory.SPRZATANIE,
    title: 'Mycie okien',
    description: '8 okien standardowych. Mieszkanie na 3 piętrze.',
    locationLat: 52.21,
    locationLng: 21.035,
    address: 'ul. Mokotowska 15/8, 00-640 Warszawa',
    budgetAmount: 120,
    status: TaskStatus.DISPUTED,
    acceptedAt: new Date(Date.now() - 172800000), // 2 days ago
    startedAt: new Date(Date.now() - 169200000),
    completedAt: new Date(Date.now() - 165600000),
    completionPhotos: ['https://example.com/dispute1.jpg'],
    scheduledAt: null,
  },
];

// Sample Ratings
export const seedRatings = [
  {
    id: '44444444-4444-4444-4444-444444444441',
    taskId: seedTasks[5].id, // Completed task
    fromUserId: seedClients[2].id,
    toUserId: seedContractors[0].user.id,
    rating: 5,
    comment: 'Bardzo szybko i profesjonalnie. Polecam!',
  },
];

// Admin user for dashboard
export const seedAdmin = {
  id: '00000000-0000-0000-0000-000000000001',
  type: UserType.CLIENT, // Admin is a special client
  phone: '+48000000001',
  email: 'admin@szybkafucha.pl',
  name: 'Administrator',
  status: UserStatus.ACTIVE,
  avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=admin',
};
