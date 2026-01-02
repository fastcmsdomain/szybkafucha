/**
 * Dashboard Page
 * Overview metrics and charts
 */
import React from 'react';
import { Box, Flex, Text, HStack } from '@chakra-ui/react';

// Mock data for dashboard
const STATS = [
  { label: 'Aktywni użytkownicy', value: '1,234', change: '+12%', icon: '👥', bgColor: '#3B82F615' },
  { label: 'Zlecenia dzisiaj', value: '89', change: '+8%', icon: '📋', bgColor: '#10B98115' },
  { label: 'GMV (tydzień)', value: '45,230 zł', change: '+23%', icon: '💰', bgColor: '#8B5CF615' },
  { label: 'Śr. czas realizacji', value: '1h 42m', change: '-5%', icon: '⏱️', bgColor: '#F59E0B15' },
];

const RECENT_TASKS = [
  { id: '1', client: 'Anna K.', contractor: 'Michał W.', category: 'Paczki', status: 'completed', amount: 45 },
  { id: '2', client: 'Tomasz M.', contractor: 'Karolina S.', category: 'Zakupy', status: 'in_progress', amount: 75 },
  { id: '3', client: 'Ewa P.', contractor: '—', category: 'Kolejki', status: 'created', amount: 60 },
  { id: '4', client: 'Piotr Z.', contractor: 'Adam B.', category: 'Montaż', status: 'accepted', amount: 120 },
  { id: '5', client: 'Maria L.', contractor: 'Jan K.', category: 'Sprzątanie', status: 'completed', amount: 150 },
];

// Status label helper
const getStatusLabel = (status: string) => {
  const labels: Record<string, { text: string; bgColor: string; color: string }> = {
    created: { text: 'Nowe', bgColor: '#64748B20', color: '#64748B' },
    accepted: { text: 'Przyjęte', bgColor: '#3B82F620', color: '#3B82F6' },
    in_progress: { text: 'W trakcie', bgColor: '#F59E0B20', color: '#F59E0B' },
    completed: { text: 'Zakończone', bgColor: '#10B98120', color: '#10B981' },
  };
  return labels[status] || { text: status, bgColor: '#64748B20', color: '#64748B' };
};

const Dashboard: React.FC = () => {
  return (
    <Box>
      <Text fontSize="2xl" fontWeight="bold" mb={6}>Dashboard</Text>

      {/* Alert */}
      <Box bg="orange.50" p={3} borderRadius="lg" mb={6}>
        <HStack gap={2}>
          <span>⚠️</span>
          <Text fontSize="sm">3 nowe spory do rozwiązania</Text>
        </HStack>
      </Box>

      {/* Stats Grid */}
      <Flex gap={6} mb={8} flexWrap="wrap">
        {STATS.map((stat, i) => (
          <Box
            key={i}
            bg="white"
            p={5}
            borderRadius="xl"
            boxShadow="sm"
            flex="1"
            minW="200px"
          >
            <Box mb={3}>
              <Box
                display="inline-flex"
                p={2}
                borderRadius="lg"
                bg={stat.bgColor}
                fontSize="xl"
              >
                {stat.icon}
              </Box>
            </Box>
            <Text color="gray.500" fontSize="sm" mb={1}>{stat.label}</Text>
            <Text fontSize="2xl" fontWeight="bold">{stat.value}</Text>
            <Text fontSize="sm" color={stat.change.startsWith('+') ? 'green.500' : 'red.500'}>
              {stat.change} vs poprzedni tydzień
            </Text>
          </Box>
        ))}
      </Flex>

      {/* Recent Tasks */}
      <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden">
        <Box p={4} borderBottom="1px solid" borderColor="gray.100">
          <Text fontWeight="semibold">Ostatnie zlecenia</Text>
        </Box>
        <Box overflowX="auto">
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #E2E8F0' }}>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Klient</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Wykonawca</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Kategoria</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Status</th>
                <th style={{ padding: '12px 16px', textAlign: 'right', fontSize: '12px', color: '#64748B', fontWeight: 600 }}>Kwota</th>
              </tr>
            </thead>
            <tbody>
              {RECENT_TASKS.map((task) => {
                const status = getStatusLabel(task.status);
                return (
                  <tr key={task.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                    <td style={{ padding: '12px 16px' }}>{task.client}</td>
                    <td style={{ padding: '12px 16px', color: task.contractor === '—' ? '#94A3B8' : 'inherit' }}>{task.contractor}</td>
                    <td style={{ padding: '12px 16px' }}>{task.category}</td>
                    <td style={{ padding: '12px 16px' }}>
                      <span style={{
                        padding: '4px 8px',
                        borderRadius: '9999px',
                        fontSize: '12px',
                        fontWeight: 500,
                        backgroundColor: status.bgColor,
                        color: status.color
                      }}>
                        {status.text}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 500 }}>{task.amount} zł</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </Box>
      </Box>
    </Box>
  );
};

export default Dashboard;
