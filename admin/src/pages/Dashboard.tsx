/**
 * Dashboard Page
 * Overview metrics and charts
 * Connected to real database via API
 */
import React, { useState, useEffect, useCallback } from 'react';
import { Box, Flex, Text, HStack, Spinner, VStack, Button } from '@chakra-ui/react';

// Types
interface Subscriber {
  id: string;
  name: string;
  email: string;
  city: string | null;
  userType: 'client' | 'contractor';
  source: string;
  isActive: boolean;
  services: string[];
  comments: string;
  subscribedAt: string | null;
  createdAt: string;
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
  // Use relative path when deployed to szybkafucha.app/admin
  // Falls back to absolute URL for local development
  const isProduction = window.location.hostname === 'szybkafucha.app' || 
                       window.location.hostname === 'www.szybkafucha.app';
  
  if (isProduction) {
    return '/api/subscribers.php';
  }
  // For local development, use absolute URL
  return 'https://szybkafucha.app/api/subscribers.php';
};

const Dashboard: React.FC = () => {
  // State
  const [subscribers, setSubscribers] = useState<Subscriber[]>([]);
  const [stats, setStats] = useState<ApiResponse['stats'] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch subscribers from API
  const fetchSubscribers = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    const apiUrl = getApiEndpoint();
    console.log('[Dashboard] Fetching subscribers from:', apiUrl);
    
    try {
      const response = await fetch(apiUrl, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
        },
      });
      
      console.log('[Dashboard] Response status:', response.status);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data: ApiResponse = await response.json();
      console.log('[Dashboard] API Response:', { success: data.success, userCount: data.data?.length, stats: data.stats });
      
      if (data.success) {
        setSubscribers(data.data);
        setStats(data.stats);
        console.log('[Dashboard] Successfully loaded', data.data.length, 'subscribers');
      } else {
        throw new Error('API returned unsuccessful response');
      }
    } catch (err) {
      console.error('[Dashboard] Error fetching subscribers:', err);
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas pobierania danych');
    } finally {
      setLoading(false);
    }
  }, []);

  // Fetch on mount
  useEffect(() => {
    fetchSubscribers();
  }, [fetchSubscribers]);

  // Calculate service popularity
  const getServiceStats = (): { service: string; count: number }[] => {
    const serviceCounts: Record<string, number> = {};
    
    subscribers.forEach((sub) => {
      if (sub.services && Array.isArray(sub.services)) {
        sub.services.forEach((service) => {
          serviceCounts[service] = (serviceCounts[service] || 0) + 1;
        });
      }
    });
    
    return Object.entries(serviceCounts)
      .map(([service, count]) => ({ service, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 6);
  };

  // Get recent subscribers
  const getRecentSubscribers = (): Subscriber[] => {
    return subscribers.slice(0, 5);
  };

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

  // Loading state
  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minH="400px">
        <VStack gap={4}>
          <Spinner size="xl" color="red.500" borderWidth="4px" />
          <Text color="gray.500">Ładowanie danych...</Text>
        </VStack>
      </Box>
    );
  }

  // Error state
  if (error) {
    return (
      <Box>
        <Text fontSize="2xl" fontWeight="bold" mb={6}>Dashboard</Text>
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

  const serviceStats = getServiceStats();
  const recentSubscribers = getRecentSubscribers();

  return (
    <Box>
      <Flex justify="space-between" align="center" mb={6}>
        <Text fontSize="2xl" fontWeight="bold">Dashboard</Text>
        <Button colorScheme="red" size="sm" onClick={fetchSubscribers}>
          🔄 Odśwież
        </Button>
      </Flex>

      {/* Info Alert */}
      <Box bg="blue.50" p={3} borderRadius="lg" mb={6}>
        <HStack gap={2}>
          <span>📊</span>
          <Text fontSize="sm">Dane z formularza ulepszeń aplikacji (newsletter)</Text>
        </HStack>
      </Box>

      {/* Stats Grid */}
      {stats && (
        <Flex gap={6} mb={8} flexWrap="wrap">
          <Box bg="white" p={5} borderRadius="xl" boxShadow="sm" flex="1" minW="200px">
            <Box mb={3}>
              <Box display="inline-flex" p={2} borderRadius="lg" bg="#3B82F615" fontSize="xl">
                👥
              </Box>
            </Box>
            <Text color="gray.500" fontSize="sm" mb={1}>Wszystkich zapisanych</Text>
            <Text fontSize="2xl" fontWeight="bold">{stats.total}</Text>
            <Text fontSize="sm" color="green.500">
              {stats.active} aktywnych
            </Text>
          </Box>

          <Box bg="white" p={5} borderRadius="xl" boxShadow="sm" flex="1" minW="200px">
            <Box mb={3}>
              <Box display="inline-flex" p={2} borderRadius="lg" bg="#3B82F615" fontSize="xl">
                🙋
              </Box>
            </Box>
            <Text color="gray.500" fontSize="sm" mb={1}>Zleceniodawcy</Text>
            <Text fontSize="2xl" fontWeight="bold" color="blue.500">{stats.clients}</Text>
            <Text fontSize="sm" color="gray.500">
              {stats.total > 0 ? Math.round((stats.clients / stats.total) * 100) : 0}% wszystkich
            </Text>
          </Box>

          <Box bg="white" p={5} borderRadius="xl" boxShadow="sm" flex="1" minW="200px">
            <Box mb={3}>
              <Box display="inline-flex" p={2} borderRadius="lg" bg="#8B5CF615" fontSize="xl">
                💪
              </Box>
            </Box>
            <Text color="gray.500" fontSize="sm" mb={1}>Wykonawcy</Text>
            <Text fontSize="2xl" fontWeight="bold" color="purple.500">{stats.contractors}</Text>
            <Text fontSize="sm" color="gray.500">
              {stats.total > 0 ? Math.round((stats.contractors / stats.total) * 100) : 0}% wszystkich
            </Text>
          </Box>

          <Box bg="white" p={5} borderRadius="xl" boxShadow="sm" flex="1" minW="200px">
            <Box mb={3}>
              <Box display="inline-flex" p={2} borderRadius="lg" bg="#10B98115" fontSize="xl">
                💬
              </Box>
            </Box>
            <Text color="gray.500" fontSize="sm" mb={1}>Z komentarzami</Text>
            <Text fontSize="2xl" fontWeight="bold" color="green.500">
              {subscribers.filter((s) => s.comments && s.comments.length > 0).length}
            </Text>
            <Text fontSize="sm" color="gray.500">
              sugestie użytkowników
            </Text>
          </Box>
        </Flex>
      )}

      {/* Two columns: Popular Services & Recent Subscribers */}
      <Flex gap={6} flexWrap="wrap">
        {/* Popular Services */}
        <Box bg="white" borderRadius="xl" boxShadow="sm" flex="1" minW="300px">
          <Box p={4} borderBottom="1px solid" borderColor="gray.100">
            <Text fontWeight="semibold">🎯 Najpopularniejsze usługi</Text>
          </Box>
          <Box p={4}>
            {serviceStats.length > 0 ? (
              <VStack align="stretch" gap={3}>
                {serviceStats.map(({ service, count }) => (
                  <Flex key={service} justify="space-between" align="center">
                    <Text>{SERVICE_LABELS[service] || service}</Text>
                    <Box
                      bg="red.50"
                      color="red.600"
                      px={3}
                      py={1}
                      borderRadius="full"
                      fontSize="sm"
                      fontWeight="medium"
                    >
                      {count} osób
                    </Box>
                  </Flex>
                ))}
              </VStack>
            ) : (
              <Text color="gray.500" fontSize="sm">Brak danych o usługach</Text>
            )}
          </Box>
        </Box>

        {/* Recent Subscribers */}
        <Box bg="white" borderRadius="xl" boxShadow="sm" flex="2" minW="400px" overflow="hidden">
          <Box p={4} borderBottom="1px solid" borderColor="gray.100">
            <Text fontWeight="semibold">🆕 Ostatnio zapisani</Text>
          </Box>
          <Box overflowX="auto">
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid #E2E8F0' }}>
                  <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Użytkownik</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Miasto</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Typ</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Źródło</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Data</th>
                </tr>
              </thead>
              <tbody>
                {recentSubscribers.length > 0 ? (
                  recentSubscribers.map((sub) => (
                    <tr key={sub.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                      <td style={{ padding: '12px 16px' }}>
                        <Box>
                          <Text fontWeight="medium">{sub.name}</Text>
                          <Text fontSize="sm" color="gray.500">{sub.email}</Text>
                        </Box>
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        <Text fontSize="sm" color="gray.600">{sub.city || '—'}</Text>
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        <span style={{
                          padding: '4px 8px',
                          borderRadius: '9999px',
                          fontSize: '12px',
                          backgroundColor: sub.userType === 'contractor' ? '#8B5CF620' : '#3B82F620',
                          color: sub.userType === 'contractor' ? '#8B5CF6' : '#3B82F6'
                        }}>
                          {sub.userType === 'contractor' ? 'Wykonawca' : 'Zleceniodawca'}
                        </span>
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        <Text fontSize="sm" color="gray.600">{sub.source || 'landing_page'}</Text>
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        <Text fontSize="sm">{formatDate(sub.subscribedAt || sub.createdAt)}</Text>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={5} style={{ padding: '20px', textAlign: 'center' }}>
                      <Text color="gray.500">Brak zapisanych użytkowników</Text>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </Box>
        </Box>
      </Flex>
    </Box>
  );
};

export default Dashboard;
