/**
 * Disputes Page
 * Dispute resolution management
 */
import React from 'react';
import { Box, Text, HStack } from '@chakra-ui/react';

// Mock disputes data
const MOCK_DISPUTES = [
  { id: '1', taskId: 'T-1234', title: 'Paczka nie dostarczona', client: 'Anna K.', contractor: 'Michał W.', status: 'open', amount: 45 },
  { id: '2', taskId: 'T-1189', title: 'Niekompletne zakupy', client: 'Piotr Z.', contractor: 'Karolina S.', status: 'open', amount: 75 },
  { id: '3', taskId: 'T-1102', title: 'Uszkodzony mebel', client: 'Maria L.', contractor: 'Adam B.', status: 'resolved', amount: 120 },
];

const Disputes: React.FC = () => {
  const openDisputes = MOCK_DISPUTES.filter(d => d.status === 'open');
  const resolvedDisputes = MOCK_DISPUTES.filter(d => d.status === 'resolved');

  return (
    <Box>
      <Text fontSize="2xl" fontWeight="bold" mb={6}>Spory</Text>

      {/* Alert */}
      {openDisputes.length > 0 && (
        <Box bg="orange.50" p={4} borderRadius="lg" mb={6} border="1px solid" borderColor="orange.200">
          <HStack gap={2}>
            <span>⚠️</span>
            <Text>Masz {openDisputes.length} otwartych sporów do rozwiązania</Text>
          </HStack>
        </Box>
      )}

      {/* Open disputes */}
      <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden" mb={6}>
        <Box p={4} borderBottom="1px solid" borderColor="gray.100">
          <Text fontWeight="semibold">Otwarte spory ({openDisputes.length})</Text>
        </Box>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #E2E8F0' }}>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Zlecenie</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Problem</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Klient</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Wykonawca</th>
              <th style={{ padding: '12px 16px', textAlign: 'right', fontSize: '12px', color: '#64748B' }}>Kwota</th>
              <th style={{ padding: '12px 16px', textAlign: 'center', fontSize: '12px', color: '#64748B' }}>Akcja</th>
            </tr>
          </thead>
          <tbody>
            {openDisputes.map((dispute) => (
              <tr key={dispute.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                <td style={{ padding: '12px 16px', fontWeight: 500 }}>{dispute.taskId}</td>
                <td style={{ padding: '12px 16px' }}>{dispute.title}</td>
                <td style={{ padding: '12px 16px' }}>{dispute.client}</td>
                <td style={{ padding: '12px 16px' }}>{dispute.contractor}</td>
                <td style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 500 }}>{dispute.amount} zł</td>
                <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                  <button style={{
                    padding: '6px 12px',
                    borderRadius: '6px',
                    fontSize: '12px',
                    fontWeight: 500,
                    backgroundColor: '#E94560',
                    color: 'white',
                    border: 'none',
                    cursor: 'pointer'
                  }}>
                    Rozwiąż
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Box>

      {/* Resolved disputes */}
      <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden">
        <Box p={4} borderBottom="1px solid" borderColor="gray.100">
          <Text fontWeight="semibold">Rozwiązane spory</Text>
        </Box>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #E2E8F0' }}>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Zlecenie</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Problem</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Strony</th>
              <th style={{ padding: '12px 16px', textAlign: 'right', fontSize: '12px', color: '#64748B' }}>Kwota</th>
              <th style={{ padding: '12px 16px', textAlign: 'left', fontSize: '12px', color: '#64748B' }}>Status</th>
            </tr>
          </thead>
          <tbody>
            {resolvedDisputes.map((dispute) => (
              <tr key={dispute.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                <td style={{ padding: '12px 16px', fontWeight: 500 }}>{dispute.taskId}</td>
                <td style={{ padding: '12px 16px' }}>{dispute.title}</td>
                <td style={{ padding: '12px 16px' }}>{dispute.client} vs {dispute.contractor}</td>
                <td style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 500 }}>{dispute.amount} zł</td>
                <td style={{ padding: '12px 16px' }}>
                  <span style={{
                    padding: '4px 8px',
                    borderRadius: '9999px',
                    fontSize: '12px',
                    backgroundColor: '#10B98120',
                    color: '#10B981'
                  }}>
                    Rozwiązany
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Box>
    </Box>
  );
};

export default Disputes;
