/**
 * Layout Component
 * Main layout with sidebar navigation
 */
import React from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { Box, Flex, HStack, Text } from '@chakra-ui/react';

const Layout: React.FC = () => {
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    navigate('/login');
  };

  return (
    <Flex minH="100vh">
      {/* Sidebar */}
      <Box
        w="260px"
        bg="white"
        borderRight="1px solid"
        borderColor="gray.200"
        py={6}
        position="fixed"
        h="100vh"
      >
        {/* Logo */}
        <HStack px={6} mb={8} gap={3}>
          <Box
            w={10}
            h={10}
            bg="#E94560"
            borderRadius="lg"
            display="flex"
            alignItems="center"
            justifyContent="center"
            color="white"
            fontWeight="bold"
            fontSize="xl"
          >
            ⚡
          </Box>
          <Text fontSize="xl" fontWeight="bold" color="#16213E">
            Szybka<Text as="span" color="#E94560">Fucha</Text>
          </Text>
        </HStack>

        {/* Navigation */}
        <Box px={3}>
          <NavLink to="/" end>
            {({ isActive }) => (
              <HStack
                px={4}
                py={3}
                mb={1}
                borderRadius="lg"
                bg={isActive ? '#E9456010' : 'transparent'}
                color={isActive ? '#E94560' : 'gray.600'}
                fontWeight={isActive ? 'semibold' : 'normal'}
                _hover={{ bg: isActive ? '#E9456010' : 'gray.50' }}
                gap={3}
              >
                <span>🏠</span>
                <Text>Dashboard</Text>
              </HStack>
            )}
          </NavLink>
          
          <NavLink to="/users">
            {({ isActive }) => (
              <HStack
                px={4}
                py={3}
                mb={1}
                borderRadius="lg"
                bg={isActive ? '#E9456010' : 'transparent'}
                color={isActive ? '#E94560' : 'gray.600'}
                fontWeight={isActive ? 'semibold' : 'normal'}
                _hover={{ bg: isActive ? '#E9456010' : 'gray.50' }}
                gap={3}
              >
                <span>👥</span>
                <Text>Użytkownicy</Text>
              </HStack>
            )}
          </NavLink>
          
          <NavLink to="/tasks">
            {({ isActive }) => (
              <HStack
                px={4}
                py={3}
                mb={1}
                borderRadius="lg"
                bg={isActive ? '#E9456010' : 'transparent'}
                color={isActive ? '#E94560' : 'gray.600'}
                fontWeight={isActive ? 'semibold' : 'normal'}
                _hover={{ bg: isActive ? '#E9456010' : 'gray.50' }}
                gap={3}
              >
                <span>📋</span>
                <Text>Zlecenia</Text>
              </HStack>
            )}
          </NavLink>
          
          <NavLink to="/disputes">
            {({ isActive }) => (
              <HStack
                px={4}
                py={3}
                mb={1}
                borderRadius="lg"
                bg={isActive ? '#E9456010' : 'transparent'}
                color={isActive ? '#E94560' : 'gray.600'}
                fontWeight={isActive ? 'semibold' : 'normal'}
                _hover={{ bg: isActive ? '#E9456010' : 'gray.50' }}
                gap={3}
              >
                <span>⚠️</span>
                <Text>Spory</Text>
              </HStack>
            )}
          </NavLink>
        </Box>

        {/* Logout button at bottom */}
        <Box position="absolute" bottom={6} left={0} right={0} px={3}>
          <Box borderTop="1px solid" borderColor="gray.200" pt={4} mb={4} />
          <HStack
            px={4}
            py={3}
            borderRadius="lg"
            color="gray.600"
            _hover={{ bg: 'gray.50' }}
            cursor="pointer"
            onClick={handleLogout}
            gap={3}
          >
            <span>🚪</span>
            <Text>Wyloguj się</Text>
          </HStack>
        </Box>
      </Box>

      {/* Main content */}
      <Box ml="260px" flex={1} p={8} bg="gray.50">
        <Outlet />
      </Box>
    </Flex>
  );
};

export default Layout;
