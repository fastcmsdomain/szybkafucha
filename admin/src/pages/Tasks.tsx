/**
 * Tasks Page
 * Task management and monitoring
 */
import React, { useState } from 'react';
import { Box, Flex, Text, HStack, Input } from '@chakra-ui/react';

// Mock tasks data
const MOCK_TASKS = [
  { id: '1', title: 'Odbiór paczki z InPost', category: '📦 Paczki', client: 'Anna K.', contractor: 'Michał W.', status: 'completed', amount: 45 },
  { id: '2', title: 'Zakupy z Biedronki', category: '🛒 Zakupy', client: 'Tomasz M.', contractor: 'Karolina S.', status: 'in_progress', amount: 75 },
  { id: '3', title: 'Oczekiwanie w kolejce ZUS', category: '⏰ Kolejki', client: 'Ewa P.', contractor: null, status: 'created', amount: 60 },
  { id: '4', title: 'Montaż regału IKEA', category: '🔧 Montaż', client: 'Piotr Z.', contractor: 'Adam B.', status: 'accepted', amount: 120 },
  { id: '5', title: 'Sprzątanie po przeprowadzce', category: '🧹 Sprzątanie', client: 'Maria L.', contractor: 'Jan K.', status: 'completed', amount: 150 },
];

const Tasks: React.FC = () => {
  const [search, setSearch] = useState('');

  const filteredTasks = MOCK_TASKS.filter((task) =>
    task.title.toLowerCase().includes(search.toLowerCase()) ||
    task.client.toLowerCase().includes(search.toLowerCase())
  );

  // Stats
  const stats = {
    total: MOCK_TASKS.length,
    active: MOCK_TASKS.filter(t => ['created', 'accepted', 'in_progress'].includes(t.status)).length,
    completed: MOCK_TASKS.filter(t => t.status === 'completed').length,
    gmv: MOCK_TASKS.filter(t => t.status === 'completed').reduce((sum, t) => sum + t.amount, 0),
  };

  const getStatusStyle = (status: string) => {
    const styles: Record<string, { bg: string; color: string; text: string }> = {
      created: { bg: '#64748B20', color: '#64748B', text: 'Nowe' },
      accepted: { bg: '#3B82F620', color: '#3B82F6', text: 'Przyjęte' },
      in_progress: { bg: '#F59E0B20', color: '#F59E0B', text: 'W trakcie' },
      completed: { bg: '#10B98120', color: '#10B981', text: 'Zakończone' },
    };
    return styles[status] || { bg: '#64748B20', color: '#64748B', text: status };
  };

  return (
    <Box>
      <Text fontSize="2xl" fontWeight="bold" mb={6}>Zlecenia</Text>

      {/* Stats */}
      <Flex gap={4} mb={6}>
        {[
          { label: 'Wszystkie', value: stats.total },
          { label: 'Aktywne', value: stats.active, color: '#F59E0B' },
          { label: 'Zakończone', value: stats.completed, color: '#10B981' },
          { label: 'GMV', value: `${stats.gmv} zł` },
        ].map((stat, i) => (
          <Box key={i} bg="white" p={4} borderRadius="lg" boxShadow="sm" flex={1}>
            <Text fontSize="sm" color="gray.500">{stat.label}</Text>
            <Text fontSize="xl" fontWeight="bold" color={stat.color || 'inherit'}>{stat.value}</Text>
          </Box>
        ))}
      </Flex>

      {/* Search */}
      <Box bg="white" p={4} borderRadius="xl" boxShadow="sm" mb={6}>
        <HStack gap={2} maxW="300px">
          <span style={{ color: '#94A3B8' }}>🔍</span>
          <Input
            placeholder="Szukaj zlecenia..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            border="none"
            _focus={{ boxShadow: 'none' }}
          />
        </HStack>
      </Box>

      {/* Tasks table */}
      <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #E2E8F0' }}>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Zlecenie</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Kategoria</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Klient</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Wykonawca</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Status</th>
              <th style={{ padding: '12px 16px', textAlign: 'right', fontSize: '12px', color: '#64748B' }}>Kwota</th>
            </tr>
          </thead>
          <tbody>
            {filteredTasks.map((task) => {
              const style = getStatusStyle(task.status);
              return (
                <tr key={task.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                  <td style={{ padding: '12px 16px', fontWeight: 500 }}>{task.title}</td>
                  <td style={{ padding: '12px 16px' }}>{task.category}</td>
                  <td style={{ padding: '12px 16px' }}>{task.client}</td>
                  <td style={{ padding: '12px 16px', color: task.contractor ? 'inherit' : '#94A3B8' }}>
                    {task.contractor || '—'}
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    <span style={{
                      padding: '4px 8px',
                      borderRadius: '9999px',
                      fontSize: '12px',
                      backgroundColor: style.bg,
                      color: style.color
                    }}>
                      {style.text}
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
  );
};

export default Tasks;
