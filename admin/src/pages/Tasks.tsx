/**
 * Tasks Page
 * Task management and monitoring
 * Connected to backend API
 */
import React, { useState, useEffect, useCallback } from 'react';
import { Box, Flex, Text, HStack, Input, Spinner, VStack, Button } from '@chakra-ui/react';
import { tasksApi, Task, PaginatedResponse } from '../services/api';

// Category labels mapping
const CATEGORY_LABELS: Record<string, string> = {
  paczki: '📦 Paczki',
  zakupy: '🛒 Zakupy',
  kolejki: '⏰ Kolejki',
  montaz: '🔧 Montaż',
  przeprowadzki: '📦 Przeprowadzki',
  sprzatanie: '🧹 Sprzątanie',
  naprawy: '🔨 Naprawy',
  ogrod: '🌿 Ogród',
  transport: '🚗 Transport',
  zwierzeta: '🐾 Zwierzęta',
  elektryk: '⚡ Elektryk',
  hydraulik: '🔧 Hydraulik',
  malowanie: '🎨 Malowanie',
  zlota_raczka: '🛠️ Złota rączka',
  komputery: '💻 Komputery',
  sport: '🏋️ Sport',
  inne: '📋 Inne',
};

const Tasks: React.FC = () => {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [stats, setStats] = useState({
    total: 0,
    active: 0,
    completed: 0,
    gmv: 0,
  });

  // Fetch tasks from API
  const fetchTasks = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const response: PaginatedResponse<Task> = await tasksApi.getAll({
        status: statusFilter || undefined,
        limit: 100,
      });

      setTasks(response.data);

      // Calculate stats
      const allTasks = response.data;
      setStats({
        total: response.total,
        active: allTasks.filter((t) =>
          ['created', 'accepted', 'in_progress'].includes(t.status)
        ).length,
        completed: allTasks.filter((t) => t.status === 'completed').length,
        gmv: allTasks
          .filter((t) => t.status === 'completed')
          .reduce((sum, t) => sum + (t.finalAmount || t.budgetAmount), 0),
      });
    } catch (err) {
      console.error('Error fetching tasks:', err);
      setError(err instanceof Error ? err.message : 'Wystapil blad podczas pobierania danych');
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  // Fetch on mount and filter change
  useEffect(() => {
    fetchTasks();
  }, [fetchTasks]);

  // Filter tasks by search
  const filteredTasks = tasks.filter(
    (task) =>
      task.title.toLowerCase().includes(search.toLowerCase()) ||
      task.client?.name?.toLowerCase().includes(search.toLowerCase()) ||
      task.contractor?.name?.toLowerCase().includes(search.toLowerCase())
  );

  const getStatusStyle = (status: string) => {
    const styles: Record<string, { bg: string; color: string; text: string }> = {
      created: { bg: '#64748B20', color: '#64748B', text: 'Nowe' },
      accepted: { bg: '#3B82F620', color: '#3B82F6', text: 'Przyjete' },
      in_progress: { bg: '#F59E0B20', color: '#F59E0B', text: 'W trakcie' },
      completed: { bg: '#10B98120', color: '#10B981', text: 'Zakonczone' },
      cancelled: { bg: '#EF444420', color: '#EF4444', text: 'Anulowane' },
      disputed: { bg: '#DC262620', color: '#DC2626', text: 'Sporne' },
    };
    return styles[status] || { bg: '#64748B20', color: '#64748B', text: status };
  };

  // Loading state
  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minH="400px">
        <VStack gap={4}>
          <Spinner size="xl" color="red.500" borderWidth="4px" />
          <Text color="gray.500">Ladowanie zlecen...</Text>
        </VStack>
      </Box>
    );
  }

  // Error state
  if (error) {
    return (
      <Box>
        <Text fontSize="2xl" fontWeight="bold" mb={6}>
          Zlecenia
        </Text>
        <Box bg="red.50" p={6} borderRadius="xl" border="1px solid" borderColor="red.200">
          <Text color="red.600" fontWeight="medium">
            Blad ladowania danych
          </Text>
          <Text color="red.500" fontSize="sm" mt={2}>
            {error}
          </Text>
          <Text color="gray.500" fontSize="xs" mt={2}>
            Upewnij sie, ze backend jest uruchomiony i jestes zalogowany jako admin.
          </Text>
          <Button mt={4} colorScheme="red" size="sm" onClick={fetchTasks}>
            Sprobuj ponownie
          </Button>
        </Box>
      </Box>
    );
  }

  return (
    <Box>
      <Flex justify="space-between" align="center" mb={6}>
        <Text fontSize="2xl" fontWeight="bold">
          Zlecenia
        </Text>
        <Button colorScheme="red" size="sm" onClick={fetchTasks}>
          Odswiez
        </Button>
      </Flex>

      {/* Stats */}
      <Flex gap={4} mb={6}>
        {[
          { label: 'Wszystkie', value: stats.total },
          { label: 'Aktywne', value: stats.active, color: '#F59E0B' },
          { label: 'Zakonczone', value: stats.completed, color: '#10B981' },
          { label: 'GMV', value: `${stats.gmv} zl` },
        ].map((stat, i) => (
          <Box key={i} bg="white" p={4} borderRadius="lg" boxShadow="sm" flex={1}>
            <Text fontSize="sm" color="gray.500">
              {stat.label}
            </Text>
            <Text fontSize="xl" fontWeight="bold" color={stat.color || 'inherit'}>
              {stat.value}
            </Text>
          </Box>
        ))}
      </Flex>

      {/* Search and Filters */}
      <Box bg="white" p={4} borderRadius="xl" boxShadow="sm" mb={6}>
        <Flex gap={4} flexWrap="wrap">
          <HStack gap={2} flex={1} minW="200px">
            <span style={{ color: '#94A3B8' }}>🔍</span>
            <Input
              placeholder="Szukaj zlecenia..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              border="none"
              _focus={{ boxShadow: 'none' }}
            />
          </HStack>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            style={{
              padding: '8px 12px',
              borderRadius: '6px',
              border: '1px solid #E2E8F0',
              backgroundColor: 'white',
              maxWidth: '200px',
              cursor: 'pointer',
            }}
          >
            <option value="">Wszystkie statusy</option>
            <option value="created">Nowe</option>
            <option value="accepted">Przyjete</option>
            <option value="in_progress">W trakcie</option>
            <option value="completed">Zakonczone</option>
            <option value="cancelled">Anulowane</option>
            <option value="disputed">Sporne</option>
          </select>
        </Flex>
      </Box>

      {/* Tasks table */}
      <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden">
        {filteredTasks.length === 0 ? (
          <Box p={8} textAlign="center">
            <Text color="gray.500">Brak zlecen do wyswietlenia</Text>
          </Box>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #E2E8F0' }}>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'left',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Zlecenie
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'left',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Kategoria
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'left',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Klient
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'left',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Wykonawca
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'left',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Status
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'right',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Kwota
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredTasks.map((task) => {
                const style = getStatusStyle(task.status);
                return (
                  <tr key={task.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                    <td style={{ padding: '12px 16px' }}>
                      <Text fontWeight={500}>{task.title}</Text>
                      <Text fontSize="xs" color="gray.500">
                        {task.address}
                      </Text>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      {CATEGORY_LABELS[task.category] || task.category}
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      {task.client?.name || '—'}
                    </td>
                    <td
                      style={{
                        padding: '12px 16px',
                        color: task.contractor ? 'inherit' : '#94A3B8',
                      }}
                    >
                      {task.contractor?.name || '—'}
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <span
                        style={{
                          padding: '4px 8px',
                          borderRadius: '9999px',
                          fontSize: '12px',
                          backgroundColor: style.bg,
                          color: style.color,
                        }}
                      >
                        {style.text}
                      </span>
                    </td>
                    <td
                      style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 500 }}
                    >
                      {task.finalAmount || task.budgetAmount} zl
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </Box>
    </Box>
  );
};

export default Tasks;
