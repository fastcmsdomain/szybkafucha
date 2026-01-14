/**
 * Disputes Page
 * Dispute resolution management
 * Connected to backend API
 */
import React, { useState, useEffect, useCallback } from 'react';
import { Box, Text, HStack, Spinner, VStack, Button, Flex, Textarea } from '@chakra-ui/react';
import { Dialog } from '@ark-ui/react';
import { disputesApi, Dispute, DisputeResolution, PaginatedResponse } from '../services/api';

const Disputes: React.FC = () => {
  const [disputes, setDisputes] = useState<Dispute[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedDispute, setSelectedDispute] = useState<Dispute | null>(null);
  const [resolutionNotes, setResolutionNotes] = useState('');
  const [resolving, setResolving] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Fetch disputes from API
  const fetchDisputes = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const response: PaginatedResponse<Dispute> = await disputesApi.getAll({
        limit: 100,
      });
      setDisputes(response.data);
    } catch (err) {
      console.error('Error fetching disputes:', err);
      setError(err instanceof Error ? err.message : 'Wystapil blad podczas pobierania danych');
    } finally {
      setLoading(false);
    }
  }, []);

  // Fetch on mount
  useEffect(() => {
    fetchDisputes();
  }, [fetchDisputes]);

  // Handle resolve dispute
  const handleResolve = async (resolution: DisputeResolution) => {
    if (!selectedDispute) return;

    setResolving(true);
    try {
      await disputesApi.resolve(selectedDispute.id, resolution, resolutionNotes);
      closeModal();
      fetchDisputes(); // Refresh list
    } catch (err) {
      console.error('Error resolving dispute:', err);
      alert(err instanceof Error ? err.message : 'Blad podczas rozwiazywania sporu');
    } finally {
      setResolving(false);
    }
  };

  // Modal handlers
  const closeModal = () => {
    setIsModalOpen(false);
    setResolutionNotes('');
    setSelectedDispute(null);
  };

  // Open resolution modal
  const openResolveModal = (dispute: Dispute) => {
    setSelectedDispute(dispute);
    setResolutionNotes('');
    setIsModalOpen(true);
  };

  // Split disputes by status
  const openDisputes = disputes.filter((d) => d.status === 'disputed');
  const resolvedDisputes = disputes.filter((d) => d.status !== 'disputed');

  // Loading state
  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minH="400px">
        <VStack gap={4}>
          <Spinner size="xl" color="red.500" borderWidth="4px" />
          <Text color="gray.500">Ladowanie sporow...</Text>
        </VStack>
      </Box>
    );
  }

  // Error state
  if (error) {
    return (
      <Box>
        <Text fontSize="2xl" fontWeight="bold" mb={6}>
          Spory
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
          <Button mt={4} colorScheme="red" size="sm" onClick={fetchDisputes}>
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
          Spory
        </Text>
        <Button colorScheme="red" size="sm" onClick={fetchDisputes}>
          Odswiez
        </Button>
      </Flex>

      {/* Alert */}
      {openDisputes.length > 0 && (
        <Box
          bg="orange.50"
          p={4}
          borderRadius="lg"
          mb={6}
          border="1px solid"
          borderColor="orange.200"
        >
          <HStack gap={2}>
            <span>⚠️</span>
            <Text>
              Masz {openDisputes.length} otwartych sporow do rozwiazania
            </Text>
          </HStack>
        </Box>
      )}

      {/* Open disputes */}
      <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden" mb={6}>
        <Box p={4} borderBottom="1px solid" borderColor="gray.100">
          <Text fontWeight="semibold">Otwarte spory ({openDisputes.length})</Text>
        </Box>
        {openDisputes.length === 0 ? (
          <Box p={8} textAlign="center">
            <Text color="gray.500">Brak otwartych sporow</Text>
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
                  Problem
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
                    textAlign: 'right',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Kwota
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'center',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Akcja
                </th>
              </tr>
            </thead>
            <tbody>
              {openDisputes.map((dispute) => (
                <tr key={dispute.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                  <td style={{ padding: '12px 16px', fontWeight: 500 }}>
                    {dispute.id.slice(0, 8)}...
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    {dispute.cancellationReason || dispute.title}
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    {dispute.client?.name || '—'}
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    {dispute.contractor?.name || '—'}
                  </td>
                  <td
                    style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 500 }}
                  >
                    {dispute.budgetAmount} zl
                  </td>
                  <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                    <button
                      onClick={() => openResolveModal(dispute)}
                      style={{
                        padding: '6px 12px',
                        borderRadius: '6px',
                        fontSize: '12px',
                        fontWeight: 500,
                        backgroundColor: '#E94560',
                        color: 'white',
                        border: 'none',
                        cursor: 'pointer',
                      }}
                    >
                      Rozwiaz
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Box>

      {/* Resolved disputes */}
      <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden">
        <Box p={4} borderBottom="1px solid" borderColor="gray.100">
          <Text fontWeight="semibold">Rozwiazane spory ({resolvedDisputes.length})</Text>
        </Box>
        {resolvedDisputes.length === 0 ? (
          <Box p={8} textAlign="center">
            <Text color="gray.500">Brak rozwiazanych sporow</Text>
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
                  Problem
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'left',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Strony
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
              </tr>
            </thead>
            <tbody>
              {resolvedDisputes.map((dispute) => (
                <tr key={dispute.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                  <td style={{ padding: '12px 16px', fontWeight: 500 }}>
                    {dispute.id.slice(0, 8)}...
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    {dispute.cancellationReason || dispute.title}
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    {dispute.client?.name || '—'} vs {dispute.contractor?.name || '—'}
                  </td>
                  <td
                    style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 500 }}
                  >
                    {dispute.budgetAmount} zl
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    <span
                      style={{
                        padding: '4px 8px',
                        borderRadius: '9999px',
                        fontSize: '12px',
                        backgroundColor: '#10B98120',
                        color: '#10B981',
                      }}
                    >
                      Rozwiazany
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Box>

      {/* Resolution Modal */}
      <Dialog.Root open={isModalOpen} onOpenChange={(e) => !e.open && closeModal()}>
        <Dialog.Backdrop
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            zIndex: 1000,
          }}
        />
        <Dialog.Positioner
          style={{
            position: 'fixed',
            inset: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1001,
          }}
        >
          <Dialog.Content
            style={{
              backgroundColor: 'white',
              borderRadius: '12px',
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
              padding: '24px',
              maxWidth: '500px',
              width: '90%',
              maxHeight: '90vh',
              overflow: 'auto',
            }}
          >
            <Dialog.Title
              style={{
                fontSize: '18px',
                fontWeight: 600,
                marginBottom: '16px',
              }}
            >
              Rozwiaz spor
            </Dialog.Title>
            <Dialog.CloseTrigger
              style={{
                position: 'absolute',
                top: '16px',
                right: '16px',
                background: 'none',
                border: 'none',
                fontSize: '20px',
                cursor: 'pointer',
                color: '#64748B',
              }}
            >
              ×
            </Dialog.CloseTrigger>

            {selectedDispute && (
              <VStack align="stretch" gap={4}>
                <Box bg="gray.50" p={4} borderRadius="md">
                  <Text fontSize="sm" color="gray.600">
                    Zlecenie: {selectedDispute.title}
                  </Text>
                  <Text fontSize="sm" color="gray.600">
                    Kwota: {selectedDispute.budgetAmount} zl
                  </Text>
                  <Text fontSize="sm" color="gray.600">
                    Klient: {selectedDispute.client?.name || '—'}
                  </Text>
                  <Text fontSize="sm" color="gray.600">
                    Wykonawca: {selectedDispute.contractor?.name || '—'}
                  </Text>
                  {selectedDispute.cancellationReason && (
                    <Text fontSize="sm" color="red.600" mt={2}>
                      Powod: {selectedDispute.cancellationReason}
                    </Text>
                  )}
                </Box>

                <Box>
                  <Text fontWeight="medium" mb={2}>
                    Notatki do rozwiazania:
                  </Text>
                  <Textarea
                    value={resolutionNotes}
                    onChange={(e) => setResolutionNotes(e.target.value)}
                    placeholder="Opisz powod decyzji..."
                    rows={3}
                  />
                </Box>
              </VStack>
            )}

            <HStack gap={2} mt={6} flexWrap="wrap">
              <Button
                colorScheme="green"
                onClick={() => handleResolve('pay_contractor')}
                loading={resolving}
                size="sm"
              >
                Zaplac wykonawcy
              </Button>
              <Button
                colorScheme="blue"
                onClick={() => handleResolve('refund')}
                loading={resolving}
                size="sm"
              >
                Zwrot klientowi
              </Button>
              <Button
                colorScheme="orange"
                onClick={() => handleResolve('split')}
                loading={resolving}
                size="sm"
              >
                Podziel 50/50
              </Button>
              <Button variant="ghost" onClick={closeModal} size="sm">
                Anuluj
              </Button>
            </HStack>
          </Dialog.Content>
        </Dialog.Positioner>
      </Dialog.Root>
    </Box>
  );
};

export default Disputes;
