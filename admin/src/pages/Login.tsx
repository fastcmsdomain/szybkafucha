/**
 * Login Page
 * Admin authentication via backend API
 */
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Flex, Text, Input, Button } from '@chakra-ui/react';
import { authConfig } from '../config/auth.config';

// API base URL
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000/api/v1';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      // Try backend authentication first
      const response = await fetch(`${API_BASE_URL}/auth/email/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      if (response.ok) {
        const data = await response.json();

        // Check if user is admin (via @szybkafucha.pl email domain)
        const user = data.user;
        const isAdmin = user?.email?.toLowerCase().endsWith('@szybkafucha.pl');

        if (!isAdmin) {
          setError('Brak uprawnień administratora. Wymagany email @szybkafucha.pl');
          return;
        }

        localStorage.setItem(authConfig.tokenKey, data.accessToken);
        navigate('/');
        return;
      }

      // Backend auth failed, try fallback to mock auth for development
      if (email === authConfig.adminEmail && password === authConfig.adminPassword) {
        // Use mock token - will only work if backend is not validating JWT
        localStorage.setItem(authConfig.tokenKey, authConfig.tokenValue);
        navigate('/');
        return;
      }

      // Get error message from response
      const errorData = await response.json().catch(() => ({}));
      setError(errorData.message || 'Nieprawidlowy email lub haslo');
    } catch (err) {
      // Network error - try mock auth for development
      console.error('Auth error:', err);

      if (email === authConfig.adminEmail && password === authConfig.adminPassword) {
        localStorage.setItem(authConfig.tokenKey, authConfig.tokenValue);
        navigate('/');
        return;
      }

      setError('Nie mozna polaczyc sie z serwerem. Sprawdz czy backend jest uruchomiony.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Flex minH="100vh" align="center" justify="center" bg="gray.50">
      <Box bg="white" p={8} borderRadius="xl" boxShadow="lg" w="400px">
        {/* Logo */}
        <Flex direction="column" align="center" mb={8}>
          <Box
            w={16}
            h={16}
            bg="#E94560"
            borderRadius="xl"
            display="flex"
            alignItems="center"
            justifyContent="center"
            color="white"
            fontWeight="bold"
            fontSize="3xl"
            mb={4}
          >
            ⚡
          </Box>
          <Text fontSize="2xl" fontWeight="bold" color="#16213E">
            Szybka<Text as="span" color="#E94560">Fucha</Text>
          </Text>
          <Text color="gray.500" fontSize="sm" mt={1}>
            Panel Administracyjny
          </Text>
        </Flex>

        {/* Error message */}
        {error && (
          <Box bg="red.50" color="red.500" p={3} borderRadius="lg" mb={4} fontSize="sm">
            {error}
          </Box>
        )}

        {/* Login form */}
        <form onSubmit={handleSubmit}>
          <Box mb={4}>
            <Text fontSize="sm" fontWeight="medium" mb={1}>Email</Text>
            <Input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@szybkafucha.pl"
              required
            />
          </Box>

          <Box mb={6}>
            <Text fontSize="sm" fontWeight="medium" mb={1}>Haslo</Text>
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="********"
              required
            />
          </Box>

          <Button
            type="submit"
            w="full"
            bg="#E94560"
            color="white"
            _hover={{ bg: '#d13a54' }}
            loading={isLoading}
          >
            Zaloguj sie
          </Button>
        </form>

        {/* Dev hint */}
        {process.env.NODE_ENV === 'development' && (
          <Text fontSize="xs" color="gray.400" textAlign="center" mt={6}>
            Dev: uzyj konta z email auth lub {authConfig.adminEmail}
          </Text>
        )}
      </Box>
    </Flex>
  );
};

export default Login;
