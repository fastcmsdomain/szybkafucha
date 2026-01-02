/**
 * Login Page
 * Admin authentication
 */
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Flex, Text, Input, Button } from '@chakra-ui/react';

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

    // Mock login
    if (email === 'admin@szybkafucha.pl' && password === 'admin123') {
      localStorage.setItem('adminToken', 'mock-admin-token');
      navigate('/');
    } else {
      setError('Nieprawidłowy email lub hasło');
    }

    setIsLoading(false);
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
            <Text fontSize="sm" fontWeight="medium" mb={1}>Hasło</Text>
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
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
            Zaloguj się
          </Button>
        </form>

        {/* Dev hint */}
        <Text fontSize="xs" color="gray.400" textAlign="center" mt={6}>
          Dev: admin@szybkafucha.pl / admin123
        </Text>
      </Box>
    </Flex>
  );
};

export default Login;
