/**
 * Users Page
 * User management with search and filters
 */
import React, { useState } from 'react';
import { Box, Flex, Text, HStack, Input } from '@chakra-ui/react';

// Mock users data
const MOCK_USERS = [
  { id: '1', name: 'Anna Kowalska', email: 'anna.k@example.com', type: 'client', status: 'active', tasks: 12 },
  { id: '2', name: 'Michał Wiśniewski', email: 'michal.w@example.com', type: 'contractor', status: 'active', tasks: 127, rating: 4.9 },
  { id: '3', name: 'Ewa Nowak', email: 'ewa.n@example.com', type: 'contractor', status: 'pending', tasks: 0 },
  { id: '4', name: 'Piotr Zieliński', email: 'piotr.z@example.com', type: 'client', status: 'suspended', tasks: 3 },
];

const Users: React.FC = () => {
  const [search, setSearch] = useState('');

  const filteredUsers = MOCK_USERS.filter((user) =>
    user.name.toLowerCase().includes(search.toLowerCase()) ||
    user.email.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <Box>
      <Text fontSize="2xl" fontWeight="bold" mb={6}>Użytkownicy</Text>

      {/* Search */}
      <Box bg="white" p={4} borderRadius="xl" boxShadow="sm" mb={6}>
        <HStack gap={2} maxW="300px">
          <span style={{ color: '#94A3B8' }}>🔍</span>
          <Input
            placeholder="Szukaj użytkownika..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            border="none"
            _focus={{ boxShadow: 'none' }}
          />
        </HStack>
      </Box>

      {/* Users table */}
      <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #E2E8F0' }}>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Użytkownik</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Typ</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Status</th>
              <th style={{ padding: '12px 16px', textAlign: 'right', fontSize: '12px', color: '#64748B' }}>Zlecenia</th>
              <th style={{ padding: '12px 16px', textAlign: 'right', fontSize: '12px', color: '#64748B' }}>Ocena</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers.map((user) => (
              <tr key={user.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                <td style={{ padding: '12px 16px' }}>
                  <Box>
                    <Text fontWeight="medium">{user.name}</Text>
                    <Text fontSize="sm" color="gray.500">{user.email}</Text>
                  </Box>
                </td>
                <td style={{ padding: '12px 16px' }}>
                  <span style={{
                    padding: '4px 8px',
                    borderRadius: '9999px',
                    fontSize: '12px',
                    backgroundColor: user.type === 'contractor' ? '#8B5CF620' : '#3B82F620',
                    color: user.type === 'contractor' ? '#8B5CF6' : '#3B82F6'
                  }}>
                    {user.type === 'contractor' ? 'Wykonawca' : 'Zleceniodawca'}
                  </span>
                </td>
                <td style={{ padding: '12px 16px' }}>
                  <span style={{
                    padding: '4px 8px',
                    borderRadius: '9999px',
                    fontSize: '12px',
                    backgroundColor: user.status === 'active' ? '#10B98120' : user.status === 'suspended' ? '#EF444420' : '#F59E0B20',
                    color: user.status === 'active' ? '#10B981' : user.status === 'suspended' ? '#EF4444' : '#F59E0B'
                  }}>
                    {user.status === 'active' ? 'Aktywny' : user.status === 'suspended' ? 'Zawieszony' : 'Oczekujący'}
                  </span>
                </td>
                <td style={{ padding: '12px 16px', textAlign: 'right' }}>{user.tasks}</td>
                <td style={{ padding: '12px 16px', textAlign: 'right' }}>
                  {(user as any).rating ? `⭐ ${(user as any).rating}` : '—'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Box>
    </Box>
  );
};

export default Users;
