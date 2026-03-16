/**
 * Category Pricing Page
 * Manage pricing for task categories
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Flex,
  Text,
  VStack,
  HStack,
  Button,
  Spinner,
  Input,
} from '@chakra-ui/react';
import {
  categoryPricingApi,
  CategoryPricing as CategoryPricingType,
  UpdateCategoryPricingDto,
} from '../services/api';

// Category labels mapping with emojis
const CATEGORY_LABELS: Record<string, string> = {
  paczki: 'Paczki',
  zakupy: 'Zakupy',
  kolejki: 'Kolejki',
  montaz: 'Montaz',
  przeprowadzki: 'Przeprowadzki',
  sprzatanie: 'Sprzatanie',
  naprawy: 'Naprawy',
  ogrod: 'Ogrod',
  transport: 'Transport',
  zwierzeta: 'Zwierzeta',
  elektryk: 'Elektryk',
  hydraulik: 'Hydraulik',
  malowanie: 'Malowanie',
  zlota_raczka: 'Zlota raczka',
  komputery: 'Komputery',
  sport: 'Sport',
  inne: 'Inne',
};

const CATEGORY_EMOJIS: Record<string, string> = {
  paczki: '📦',
  zakupy: '🛒',
  kolejki: '⏰',
  montaz: '🔧',
  przeprowadzki: '🚚',
  sprzatanie: '🧹',
  naprawy: '🔨',
  ogrod: '🌿',
  transport: '🚗',
  zwierzeta: '🐾',
  elektryk: '⚡',
  hydraulik: '🔧',
  malowanie: '🎨',
  zlota_raczka: '🛠️',
  komputery: '💻',
  sport: '🏋️',
  inne: '📋',
};

interface EditModalProps {
  pricing: CategoryPricingType;
  onClose: () => void;
  onSave: (data: UpdateCategoryPricingDto) => Promise<void>;
}

const EditModal: React.FC<EditModalProps> = ({ pricing, onClose, onSave }) => {
  const [formData, setFormData] = useState<UpdateCategoryPricingDto>({
    minPrice: pricing.minPrice,
    maxPrice: pricing.maxPrice,
    suggestedPrice: pricing.suggestedPrice,
    priceUnit: pricing.priceUnit,
    estimatedMinutes: pricing.estimatedMinutes,
    isActive: pricing.isActive,
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSave = async () => {
    // Validation
    if (formData.minPrice < 35) {
      setError('Minimalna cena musi wynosic co najmniej 35 PLN');
      return;
    }
    if (formData.maxPrice <= formData.minPrice) {
      setError('Maksymalna cena musi byc wieksza od minimalnej');
      return;
    }
    if (
      formData.suggestedPrice !== null &&
      formData.suggestedPrice !== undefined &&
      (formData.suggestedPrice < formData.minPrice ||
        formData.suggestedPrice > formData.maxPrice)
    ) {
      setError('Sugerowana cena musi byc w zakresie [min, max]');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      await onSave(formData);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystapil blad');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Box
      position="fixed"
      top={0}
      left={0}
      right={0}
      bottom={0}
      bg="blackAlpha.500"
      display="flex"
      alignItems="center"
      justifyContent="center"
      zIndex={1000}
      onClick={onClose}
    >
      <Box
        bg="white"
        borderRadius="xl"
        p={6}
        w="500px"
        maxH="90vh"
        overflowY="auto"
        onClick={(e) => e.stopPropagation()}
      >
        <Text fontSize="xl" fontWeight="bold" mb={4}>
          {CATEGORY_EMOJIS[pricing.category]} Edytuj cennik:{' '}
          {CATEGORY_LABELS[pricing.category] || pricing.category}
        </Text>

        {error && (
          <Box bg="red.50" p={3} borderRadius="md" mb={4}>
            <Text color="red.600" fontSize="sm">
              {error}
            </Text>
          </Box>
        )}

        <VStack gap={4} align="stretch">
          <Box>
            <Text fontSize="sm" color="gray.600" mb={1}>
              Minimalna cena (PLN)
            </Text>
            <Input
              type="number"
              value={formData.minPrice}
              onChange={(e) =>
                setFormData({ ...formData, minPrice: parseInt(e.target.value) || 0 })
              }
              min={35}
            />
          </Box>

          <Box>
            <Text fontSize="sm" color="gray.600" mb={1}>
              Maksymalna cena (PLN)
            </Text>
            <Input
              type="number"
              value={formData.maxPrice}
              onChange={(e) =>
                setFormData({ ...formData, maxPrice: parseInt(e.target.value) || 0 })
              }
            />
          </Box>

          <Box>
            <Text fontSize="sm" color="gray.600" mb={1}>
              Sugerowana cena (PLN) - zostaw puste dla auto-obliczenia
            </Text>
            <Input
              type="number"
              value={formData.suggestedPrice ?? ''}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  suggestedPrice: e.target.value ? parseInt(e.target.value) : null,
                })
              }
              placeholder="Auto (srednia z min/max)"
            />
          </Box>

          <Box>
            <Text fontSize="sm" color="gray.600" mb={1}>
              Jednostka ceny
            </Text>
            <select
              value={formData.priceUnit}
              onChange={(e) => setFormData({ ...formData, priceUnit: e.target.value })}
              style={{
                width: '100%',
                padding: '8px 12px',
                borderRadius: '6px',
                border: '1px solid #E2E8F0',
              }}
            >
              <option value="PLN">PLN (ryczalt)</option>
              <option value="PLN/h">PLN/h (stawka godzinowa)</option>
            </select>
          </Box>

          <Box>
            <Text fontSize="sm" color="gray.600" mb={1}>
              Szacowany czas (minuty)
            </Text>
            <Input
              type="number"
              value={formData.estimatedMinutes}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  estimatedMinutes: parseInt(e.target.value) || 0,
                })
              }
              min={1}
            />
          </Box>

          <Box>
            <HStack gap={2}>
              <input
                type="checkbox"
                checked={formData.isActive}
                onChange={(e) =>
                  setFormData({ ...formData, isActive: e.target.checked })
                }
                id="isActive"
              />
              <label htmlFor="isActive">
                <Text fontSize="sm">Aktywna kategoria</Text>
              </label>
            </HStack>
          </Box>

          <Box bg="gray.50" p={3} borderRadius="md">
            <Text fontSize="sm" color="gray.600">
              Podglad wyswietlania dla uzytkownika:
            </Text>
            <Text fontWeight="medium" mt={1}>
              Sugerowana:{' '}
              {formData.suggestedPrice ??
                Math.round((formData.minPrice + formData.maxPrice) / 2)}{' '}
              PLN (zakres {formData.minPrice}-{formData.maxPrice} {formData.priceUnit})
            </Text>
          </Box>
        </VStack>

        <HStack justify="flex-end" mt={6} gap={3}>
          <Button onClick={onClose} variant="ghost">
            Anuluj
          </Button>
          <Button colorScheme="red" onClick={handleSave} loading={saving}>
            Zapisz
          </Button>
        </HStack>
      </Box>
    </Box>
  );
};

const CategoryPricing: React.FC = () => {
  const [pricings, setPricings] = useState<CategoryPricingType[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingPricing, setEditingPricing] = useState<CategoryPricingType | null>(null);
  const [resetting, setResetting] = useState(false);

  const fetchPricings = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await categoryPricingApi.getAll();
      setPricings(data);
    } catch (err) {
      console.error('Error fetching category pricing:', err);
      setError(
        err instanceof Error ? err.message : 'Wystapil blad podczas pobierania danych'
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPricings();
  }, [fetchPricings]);

  const handleSave = async (data: UpdateCategoryPricingDto) => {
    if (!editingPricing) return;

    await categoryPricingApi.update(editingPricing.category, data);
    await fetchPricings();
  };

  const handleReset = async () => {
    if (!window.confirm('Czy na pewno chcesz zresetowac wszystkie ceny do domyslnych?')) {
      return;
    }

    setResetting(true);
    try {
      await categoryPricingApi.reset();
      await fetchPricings();
    } catch (err) {
      console.error('Error resetting pricing:', err);
      alert('Wystapil blad podczas resetowania cen');
    } finally {
      setResetting(false);
    }
  };

  const handleSeed = async () => {
    try {
      const result = await categoryPricingApi.seed();
      alert(`Utworzono ${result.created} kategorii, pominieto ${result.skipped}`);
      await fetchPricings();
    } catch (err) {
      console.error('Error seeding pricing:', err);
      alert('Wystapil blad podczas seedowania');
    }
  };

  // Stats
  const stats = {
    total: pricings.length,
    active: pricings.filter((p) => p.isActive).length,
    avgMin: pricings.length
      ? Math.round(pricings.reduce((sum, p) => sum + p.minPrice, 0) / pricings.length)
      : 0,
    avgMax: pricings.length
      ? Math.round(pricings.reduce((sum, p) => sum + p.maxPrice, 0) / pricings.length)
      : 0,
  };

  // Loading state
  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minH="400px">
        <VStack gap={4}>
          <Spinner size="xl" color="red.500" borderWidth="4px" />
          <Text color="gray.500">Ladowanie cennika...</Text>
        </VStack>
      </Box>
    );
  }

  // Error state
  if (error) {
    return (
      <Box>
        <Text fontSize="2xl" fontWeight="bold" mb={6}>
          Cennik kategorii
        </Text>
        <Box bg="red.50" p={6} borderRadius="xl" border="1px solid" borderColor="red.200">
          <Text color="red.600" fontWeight="medium">
            Blad ladowania danych
          </Text>
          <Text color="red.500" fontSize="sm" mt={2}>
            {error}
          </Text>
          <Text color="gray.500" fontSize="xs" mt={2}>
            Upewnij sie, ze backend jest uruchomiony. Jesli baza danych jest pusta, uzyj
            przycisku "Seeduj domyslne".
          </Text>
          <HStack mt={4} gap={2}>
            <Button colorScheme="red" size="sm" onClick={fetchPricings}>
              Sprobuj ponownie
            </Button>
            <Button size="sm" onClick={handleSeed}>
              Seeduj domyslne
            </Button>
          </HStack>
        </Box>
      </Box>
    );
  }

  return (
    <Box>
      <Flex justify="space-between" align="center" mb={6}>
        <Text fontSize="2xl" fontWeight="bold">
          Cennik kategorii
        </Text>
        <HStack gap={2}>
          <Button size="sm" onClick={handleSeed} variant="outline">
            Seeduj brakujace
          </Button>
          <Button
            size="sm"
            onClick={handleReset}
            variant="outline"
            colorScheme="orange"
            loading={resetting}
          >
            Reset do domyslnych
          </Button>
          <Button colorScheme="red" size="sm" onClick={fetchPricings}>
            Odswiez
          </Button>
        </HStack>
      </Flex>

      {/* Stats */}
      <Flex gap={4} mb={6}>
        {[
          { label: 'Wszystkie kategorie', value: stats.total },
          { label: 'Aktywne', value: stats.active, color: '#10B981' },
          { label: 'Srednia min', value: `${stats.avgMin} PLN` },
          { label: 'Srednia max', value: `${stats.avgMax} PLN` },
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

      {/* Empty state */}
      {pricings.length === 0 ? (
        <Box bg="white" p={8} borderRadius="xl" boxShadow="sm" textAlign="center">
          <Text color="gray.500" mb={4}>
            Brak danych cenowych. Kliknij ponizej, aby zainicjalizowac domyslne ceny.
          </Text>
          <Button colorScheme="red" onClick={handleSeed}>
            Zainicjalizuj domyslne ceny
          </Button>
        </Box>
      ) : (
        /* Pricing table */
        <Box bg="white" borderRadius="xl" boxShadow="sm" overflow="hidden">
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
                  Kategoria
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'right',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Min
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'right',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Max
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'right',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Sugerowana
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'center',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Jednostka
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'center',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Czas (min)
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'center',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Status
                </th>
                <th
                  style={{
                    padding: '12px 16px',
                    textAlign: 'center',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  Akcje
                </th>
              </tr>
            </thead>
            <tbody>
              {pricings.map((pricing) => (
                <tr key={pricing.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                  <td style={{ padding: '12px 16px' }}>
                    <HStack gap={2}>
                      <span>{CATEGORY_EMOJIS[pricing.category] || '📋'}</span>
                      <Text fontWeight={500}>
                        {CATEGORY_LABELS[pricing.category] || pricing.category}
                      </Text>
                    </HStack>
                  </td>
                  <td style={{ padding: '12px 16px', textAlign: 'right' }}>
                    {pricing.minPrice} PLN
                  </td>
                  <td style={{ padding: '12px 16px', textAlign: 'right' }}>
                    {pricing.maxPrice} PLN
                  </td>
                  <td
                    style={{
                      padding: '12px 16px',
                      textAlign: 'right',
                      fontWeight: 600,
                      color: '#E94560',
                    }}
                  >
                    {pricing.suggestedPrice} PLN
                  </td>
                  <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                    <span
                      style={{
                        padding: '4px 8px',
                        borderRadius: '4px',
                        fontSize: '12px',
                        backgroundColor: pricing.priceUnit === 'PLN/h' ? '#FEF3C7' : '#E0F2FE',
                        color: pricing.priceUnit === 'PLN/h' ? '#D97706' : '#0284C7',
                      }}
                    >
                      {pricing.priceUnit}
                    </span>
                  </td>
                  <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                    {pricing.estimatedMinutes}
                  </td>
                  <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                    <span
                      style={{
                        padding: '4px 8px',
                        borderRadius: '9999px',
                        fontSize: '12px',
                        backgroundColor: pricing.isActive ? '#D1FAE5' : '#FEE2E2',
                        color: pricing.isActive ? '#059669' : '#DC2626',
                      }}
                    >
                      {pricing.isActive ? 'Aktywna' : 'Nieaktywna'}
                    </span>
                  </td>
                  <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                    <Button
                      size="sm"
                      variant="ghost"
                      colorScheme="blue"
                      onClick={() => setEditingPricing(pricing)}
                    >
                      Edytuj
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Box>
      )}

      {/* Edit modal */}
      {editingPricing && (
        <EditModal
          pricing={editingPricing}
          onClose={() => setEditingPricing(null)}
          onSave={handleSave}
        />
      )}
    </Box>
  );
};

export default CategoryPricing;
