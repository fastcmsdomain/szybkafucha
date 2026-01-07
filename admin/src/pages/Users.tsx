/**
 * Users Page
 * User management with search and filters
 * Connected to real database via API
 * Compatible with Chakra UI v3
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Flex,
  Text,
  HStack,
  Input,
  Spinner,
  Badge,
  Button,
  VStack,
} from '@chakra-ui/react';

// Types
interface Subscriber {
  id: string;
  name: string;
  email: string;
  userType: 'client' | 'contractor';
  consent: boolean;
  source: string;
  isActive: boolean;
  subscribedAt: string | null;
  unsubscribedAt: string | null;
  createdAt: string;
  updatedAt: string;
  services: string[];
  comments: string;
}

interface ApiResponse {
  success: boolean;
  data: Subscriber[];
  stats: {
    total: number;
    active: number;
    inactive: number;
    clients: number;
    contractors: number;
  };
  meta: {
    hasServicesColumn: boolean;
    hasCommentsColumn: boolean;
  };
}

// Service labels mapping
const SERVICE_LABELS: Record<string, string> = {
  cleaning: '🧹 Sprzątanie',
  shopping: '🛒 Zakupy',
  repairs: '🔧 Naprawy',
  garden: '🌿 Ogród',
  pets: '🐕 Zwierzęta',
  assembly: '🏠 Montaż',
  moving: '📦 Przeprowadzki',
  queues: '⏰ Kolejki',
  transport: '🚗 Transport',
  it: '📱 IT',
  tutoring: '🎓 Korepetycje',
  events: '🎉 Wydarzenia',
};

// API endpoint configuration
const getApiEndpoint = (): string => {
  // Always use production API (PHP not available locally)
  return 'https://szybkafucha.app/api/subscribers.php';
};

const Users: React.FC = () => {
  // State
  const [subscribers, setSubscribers] = useState<Subscriber[]>([]);
  const [stats, setStats] = useState<ApiResponse['stats'] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'client' | 'contractor'>('all');
  const [filterStatus, setFilterStatus] = useState<'all' | 'active' | 'inactive'>('all');
  const [selectedUser, setSelectedUser] = useState<Subscriber | null>(null);

  // Fetch subscribers from API
  const fetchSubscribers = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(getApiEndpoint());
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data: ApiResponse = await response.json();
      
      if (data.success) {
        setSubscribers(data.data);
        setStats(data.stats);
      } else {
        throw new Error('API returned unsuccessful response');
      }
    } catch (err) {
      console.error('Error fetching subscribers:', err);
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas pobierania danych');
    } finally {
      setLoading(false);
    }
  }, []);

  // Fetch on mount
  useEffect(() => {
    fetchSubscribers();
  }, [fetchSubscribers]);

  // Filter subscribers
  const filteredSubscribers = subscribers.filter((subscriber) => {
    // Search filter
    const matchesSearch = 
      subscriber.name.toLowerCase().includes(search.toLowerCase()) ||
      subscriber.email.toLowerCase().includes(search.toLowerCase()) ||
      (subscriber.comments && subscriber.comments.toLowerCase().includes(search.toLowerCase()));
    
    // Type filter
    const matchesType = filterType === 'all' || subscriber.userType === filterType;
    
    // Status filter
    const matchesStatus = 
      filterStatus === 'all' ||
      (filterStatus === 'active' && subscriber.isActive) ||
      (filterStatus === 'inactive' && !subscriber.isActive);
    
    return matchesSearch && matchesType && matchesStatus;
  });

  // Format date
  const formatDate = (dateString: string | null): string => {
    if (!dateString) return '—';
    const date = new Date(dateString);
    return date.toLocaleDateString('pl-PL', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  // Open user details
  const handleUserClick = (subscriber: Subscriber) => {
    setSelectedUser(subscriber);
  };

  // Close user details
  const handleCloseDetails = () => {
    setSelectedUser(null);
  };

  // Loading state
  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minH="400px">
        <VStack gap={4}>
          <Spinner size="xl" color="red.500" borderWidth="4px" />
          <Text color="gray.500">Ładowanie użytkowników...</Text>
        </VStack>
      </Box>
    );
  }

  // Error state
  if (error) {
    return (
      <Box>
        <Text fontSize="2xl" fontWeight="bold" mb={6}>Użytkownicy</Text>
        <Box bg="red.50" p={6} borderRadius="xl" border="1px solid" borderColor="red.200">
          <Text color="red.600" fontWeight="medium">❌ Błąd ładowania danych</Text>
          <Text color="red.500" fontSize="sm" mt={2}>{error}</Text>
          <Button mt={4} colorScheme="red" size="sm" onClick={fetchSubscribers}>
            Spróbuj ponownie
          </Button>
        </Box>
      </Box>
    );
  }

  return (
    <Box>
      <Flex justify="space-between" align="center" mb={6}>
        <Text fontSize="2xl" fontWeight="bold">Użytkownicy (Formularz Ulepszeń)</Text>
        <Button colorScheme="red" size="sm" onClick={fetchSubscribers}>
          🔄 Odśwież
        </Button>
      </Flex>

      {/* Stats */}
      {stats && (
        <Flex gap={4} mb={6} flexWrap="wrap">
          <Box bg="white" p={4} borderRadius="xl" boxShadow="sm" flex="1" minW="150px">
            <Text fontSize="sm" color="gray.500">Wszystkich</Text>
            <Text fontSize="2xl" fontWeight="bold">{stats.total}</Text>
          </Box>
          <Box bg="white" p={4} borderRadius="xl" boxShadow="sm" flex="1" minW="150px">
            <Text fontSize="sm" color="gray.500">Aktywnych</Text>
            <Text fontSize="2xl" fontWeight="bold" color="green.500">{stats.active}</Text>
          </Box>
          <Box bg="white" p={4} borderRadius="xl" boxShadow="sm" flex="1" minW="150px">
            <Text fontSize="sm" color="gray.500">Zleceniodawców</Text>
            <Text fontSize="2xl" fontWeight="bold" color="blue.500">{stats.clients}</Text>
          </Box>
          <Box bg="white" p={4} borderRadius="xl" boxShadow="sm" flex="1" minW="150px">
            <Text fontSize="sm" color="gray.500">Wykonawców</Text>
            <Text fontSize="2xl" fontWeight="bold" color="purple.500">{stats.contractors}</Text>
          </Box>
        </Flex>
      )}

      {/* Filters */}
      <Box bg="white" p={4} borderRadius="xl" boxShadow="sm" mb={6}>
        <Flex gap={4} flexWrap="wrap" align="center">
          {/* Search */}
          <HStack gap={2} flex="1" minW="250px">
            <span style={{ color: '#94A3B8' }}>🔍</span>
            <Input
              placeholder="Szukaj po imieniu, emailu lub komentarzu..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              border="1px solid"
              borderColor="gray.200"
            />
          </HStack>
          
          {/* Type filter */}
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value as typeof filterType)}
            style={{
              padding: '8px 12px',
              borderRadius: '6px',
              border: '1px solid #E2E8F0',
              backgroundColor: 'white',
              minWidth: '150px',
            }}
          >
            <option value="all">Wszyscy typy</option>
            <option value="client">Zleceniodawcy</option>
            <option value="contractor">Wykonawcy</option>
          </select>
          
          {/* Status filter */}
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value as typeof filterStatus)}
            style={{
              padding: '8px 12px',
              borderRadius: '6px',
              border: '1px solid #E2E8F0',
              backgroundColor: 'white',
              minWidth: '150px',
            }}
          >
            <option value="all">Wszystkie statusy</option>
            <option value="active">Aktywni</option>
            <option value="inactive">Nieaktywni</option>
          </select>
        </Flex>
      </Box>

      {/* Results count */}
      <Text fontSize="sm" color="gray.500" mb={4}>
        Wyświetlanie {filteredSubscribers.length} z {subscribers.length} użytkowników
      </Text>

      {/* User Details Panel (shown when user is selected) */}
      {selectedUser && (
        <Box 
          bg="white" 
          borderRadius="xl" 
          boxShadow="lg" 
          mb={6} 
          border="2px solid" 
          borderColor="red.200"
          overflow="hidden"
        >
          <Flex 
            justify="space-between" 
            align="center" 
            p={4} 
            bg="red.50" 
            borderBottom="1px solid" 
            borderColor="red.100"
          >
            <HStack gap={3}>
              <Text fontWeight="bold" fontSize="lg">👤 Szczegóły użytkownika</Text>
              <Badge colorScheme={selectedUser.isActive ? 'green' : 'red'}>
                {selectedUser.isActive ? 'Aktywny' : 'Nieaktywny'}
              </Badge>
            </HStack>
            <Button size="sm" onClick={handleCloseDetails}>
              ✕ Zamknij
            </Button>
          </Flex>
          
          <Box p={6}>
            <VStack align="stretch" gap={4}>
              {/* Basic info */}
              <Box bg="gray.50" p={4} borderRadius="lg">
                <Text fontWeight="bold" mb={2}>Dane podstawowe</Text>
                <Flex gap={4} flexWrap="wrap">
                  <Box flex="1" minW="200px">
                    <Text fontSize="sm" color="gray.500">Imię i nazwisko</Text>
                    <Text fontWeight="medium">{selectedUser.name}</Text>
                  </Box>
                  <Box flex="1" minW="200px">
                    <Text fontSize="sm" color="gray.500">Email</Text>
                    <Text fontWeight="medium">{selectedUser.email}</Text>
                  </Box>
                </Flex>
                <Flex gap={4} flexWrap="wrap" mt={3}>
                  <Box flex="1" minW="200px">
                    <Text fontSize="sm" color="gray.500">Typ użytkownika</Text>
                    <Badge colorScheme={selectedUser.userType === 'contractor' ? 'purple' : 'blue'}>
                      {selectedUser.userType === 'contractor' ? 'Wykonawca' : 'Zleceniodawca'}
                    </Badge>
                  </Box>
                  <Box flex="1" minW="200px">
                    <Text fontSize="sm" color="gray.500">Źródło</Text>
                    <Text>{selectedUser.source || 'landing_page'}</Text>
                  </Box>
                </Flex>
              </Box>

              {/* Services */}
              <Box bg="blue.50" p={4} borderRadius="lg">
                <Text fontWeight="bold" mb={2}>🎯 Interesujące usługi</Text>
                {selectedUser.services && selectedUser.services.length > 0 ? (
                  <Flex gap={2} flexWrap="wrap">
                    {selectedUser.services.map((service) => (
                      <Box 
                        key={service} 
                        bg="blue.100" 
                        color="blue.700" 
                        px={3} 
                        py={1} 
                        borderRadius="full" 
                        fontSize="sm"
                        fontWeight="medium"
                      >
                        {SERVICE_LABELS[service] || service}
                      </Box>
                    ))}
                  </Flex>
                ) : (
                  <Text color="gray.500" fontSize="sm">Brak wybranych usług</Text>
                )}
              </Box>

              {/* Comments */}
              <Box bg="yellow.50" p={4} borderRadius="lg">
                <Text fontWeight="bold" mb={2}>💬 Komentarz / Sugestie</Text>
                {selectedUser.comments ? (
                  <Text whiteSpace="pre-wrap">{selectedUser.comments}</Text>
                ) : (
                  <Text color="gray.500" fontSize="sm">Brak komentarza</Text>
                )}
              </Box>

              {/* Dates */}
              <Box bg="gray.50" p={4} borderRadius="lg">
                <Text fontWeight="bold" mb={2}>📅 Daty</Text>
                <Flex gap={4} flexWrap="wrap">
                  <Box flex="1" minW="150px">
                    <Text fontSize="sm" color="gray.500">Data zapisu</Text>
                    <Text fontSize="sm">{formatDate(selectedUser.subscribedAt || selectedUser.createdAt)}</Text>
                  </Box>
                  <Box flex="1" minW="150px">
                    <Text fontSize="sm" color="gray.500">Ostatnia aktualizacja</Text>
                    <Text fontSize="sm">{formatDate(selectedUser.updatedAt)}</Text>
                  </Box>
                  {selectedUser.unsubscribedAt && (
                    <Box flex="1" minW="150px">
                      <Text fontSize="sm" color="gray.500">Data wypisania</Text>
                      <Text fontSize="sm" color="red.500">{formatDate(selectedUser.unsubscribedAt)}</Text>
                    </Box>
                  )}
                </Flex>
              </Box>

              {/* Consent */}
              <Box bg={selectedUser.consent ? 'green.50' : 'red.50'} p={4} borderRadius="lg">
                <Text fontWeight="bold" mb={2}>📋 Zgoda RODO</Text>
                <Badge colorScheme={selectedUser.consent ? 'green' : 'red'}>
                  {selectedUser.consent ? '✓ Wyrażona' : '✗ Brak zgody'}
                </Badge>
              </Box>
            </VStack>
          </Box>
        </Box>
      )}

      {/* Users table */}
      <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden">
        <Box overflowX="auto">
          <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '900px' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #E2E8F0', backgroundColor: '#F8FAFC' }}>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Użytkownik</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Typ</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Status</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Źródło</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Usługi</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Data zapisu</th>
                <th style={{ padding: '12px 16px', textAlign: 'center', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Akcje</th>
              </tr>
            </thead>
            <tbody>
              {filteredSubscribers.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ padding: '40px', textAlign: 'center' }}>
                    <Text color="gray.500">Brak użytkowników spełniających kryteria</Text>
                  </td>
                </tr>
              ) : (
                filteredSubscribers.map((subscriber) => (
                  <tr 
                    key={subscriber.id} 
                    style={{ 
                      borderBottom: '1px solid #F1F5F9',
                      cursor: 'pointer',
                      transition: 'background-color 0.2s',
                      backgroundColor: selectedUser?.id === subscriber.id ? '#FEF2F2' : 'transparent',
                    }}
                    onMouseEnter={(e) => {
                      if (selectedUser?.id !== subscriber.id) {
                        e.currentTarget.style.backgroundColor = '#F8FAFC';
                      }
                    }}
                    onMouseLeave={(e) => {
                      if (selectedUser?.id !== subscriber.id) {
                        e.currentTarget.style.backgroundColor = 'transparent';
                      }
                    }}
                    onClick={() => handleUserClick(subscriber)}
                  >
                    <td style={{ padding: '12px 16px' }}>
                      <Box>
                        <Text fontWeight="medium">{subscriber.name}</Text>
                        <Text fontSize="sm" color="gray.500">{subscriber.email}</Text>
                      </Box>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <Badge
                        colorScheme={subscriber.userType === 'contractor' ? 'purple' : 'blue'}
                        borderRadius="full"
                        px={2}
                        py={1}
                      >
                        {subscriber.userType === 'contractor' ? 'Wykonawca' : 'Zleceniodawca'}
                      </Badge>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <Badge
                        colorScheme={subscriber.isActive ? 'green' : 'red'}
                        borderRadius="full"
                        px={2}
                        py={1}
                      >
                        {subscriber.isActive ? 'Aktywny' : 'Nieaktywny'}
                      </Badge>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <Text fontSize="sm" color="gray.600">
                        {subscriber.source || 'landing_page'}
                      </Text>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      {subscriber.services && subscriber.services.length > 0 ? (
                        <Flex gap={1} flexWrap="wrap">
                          {subscriber.services.slice(0, 2).map((service) => (
                            <Box 
                              key={service} 
                              bg="gray.100" 
                              color="gray.700" 
                              px={2} 
                              py={0.5} 
                              borderRadius="full" 
                              fontSize="xs"
                            >
                              {SERVICE_LABELS[service] || service}
                            </Box>
                          ))}
                          {subscriber.services.length > 2 && (
                            <Box 
                              bg="red.100" 
                              color="red.700" 
                              px={2} 
                              py={0.5} 
                              borderRadius="full" 
                              fontSize="xs"
                            >
                              +{subscriber.services.length - 2}
                            </Box>
                          )}
                        </Flex>
                      ) : (
                        <Text fontSize="sm" color="gray.400">—</Text>
                      )}
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <Text fontSize="sm">{formatDate(subscriber.subscribedAt || subscriber.createdAt)}</Text>
                    </td>
                    <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                      <Button
                        size="xs"
                        colorScheme="gray"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleUserClick(subscriber);
                        }}
                      >
                        👁️ Szczegóły
                      </Button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </Box>
      </Box>
    </Box>
  );
};

export default Users;
