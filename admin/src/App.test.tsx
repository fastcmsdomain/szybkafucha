import React from 'react';
import { render } from '@testing-library/react';

// Mock react-router-dom (full mock, no requireActual to avoid resolution issues)
jest.mock('react-router-dom', () => ({
  BrowserRouter: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  Routes: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  Route: () => null,
  Navigate: () => null,
  useNavigate: () => jest.fn(),
  useLocation: () => ({ pathname: '/' }),
  Outlet: () => null,
  Link: ({ children, to }: { children: React.ReactNode; to: string }) => <a href={to}>{children}</a>,
}));

// Mock @chakra-ui/react to avoid ark-ui dependency issues
jest.mock('@chakra-ui/react', () => ({
  Box: ({ children, ...props }: { children?: React.ReactNode }) => <div {...props}>{children}</div>,
  Flex: ({ children, ...props }: { children?: React.ReactNode }) => <div {...props}>{children}</div>,
  Text: ({ children, ...props }: { children?: React.ReactNode }) => <span {...props}>{children}</span>,
  Heading: ({ children, ...props }: { children?: React.ReactNode }) => <h1 {...props}>{children}</h1>,
  Button: ({ children, ...props }: { children?: React.ReactNode }) => <button {...props}>{children}</button>,
  Input: (props: any) => <input {...props} />,
  VStack: ({ children, ...props }: { children?: React.ReactNode }) => <div {...props}>{children}</div>,
  HStack: ({ children, ...props }: { children?: React.ReactNode }) => <div {...props}>{children}</div>,
  Container: ({ children, ...props }: { children?: React.ReactNode }) => <div {...props}>{children}</div>,
  Stack: ({ children, ...props }: { children?: React.ReactNode }) => <div {...props}>{children}</div>,
  ChakraProvider: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  useColorModeValue: (light: any, dark: any) => light,
}));

// Mock @ark-ui/react (ESM package causing Jest parse issues in CRA setup)
jest.mock('@ark-ui/react', () => ({
  Dialog: {
    Root: ({ children }: { children?: React.ReactNode }) => <div>{children}</div>,
    Backdrop: ({ children, ...props }: { children?: React.ReactNode }) => (
      <div {...props}>{children}</div>
    ),
    Positioner: ({ children, ...props }: { children?: React.ReactNode }) => (
      <div {...props}>{children}</div>
    ),
    Content: ({ children, ...props }: { children?: React.ReactNode }) => (
      <div {...props}>{children}</div>
    ),
    Title: ({ children, ...props }: { children?: React.ReactNode }) => (
      <div {...props}>{children}</div>
    ),
    CloseTrigger: ({ children, ...props }: { children?: React.ReactNode }) => (
      <button {...props}>{children}</button>
    ),
  },
}));

describe('App', () => {
  it('renders without crashing', () => {
    // Simple smoke test - the app mounts without throwing
    const App = require('./App').default;
    expect(() => render(<App />)).not.toThrow();
  });
});
