import React from 'react';
import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router';
import App from './App';

test('renders app without crashing', () => {
  const { container } = render(
    <MemoryRouter>
      <App />
    </MemoryRouter>
  );
  // App should render without errors
  expect(container).toBeInTheDocument();
});
