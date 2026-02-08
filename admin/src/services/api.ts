/**
 * API Service
 * Centralized API configuration and helpers for admin panel
 */

// API Configuration
const getApiBaseUrl = (): string => {
  // Use environment variable if available, fallback to localhost
  return process.env.REACT_APP_API_URL || 'http://localhost:3000/api/v1';
};

// Get auth token from localStorage
const getAuthToken = (): string | null => {
  return localStorage.getItem('adminToken');
};

// Base fetch wrapper with auth headers
export const apiFetch = async <T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> => {
  const token = getAuthToken();

  const response = await fetch(`${getApiBaseUrl()}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'Network error' }));
    throw new Error(error.message || `HTTP error! status: ${response.status}`);
  }

  return response.json();
};

// Task types
export interface Task {
  id: string;
  title: string;
  description: string;
  category: string;
  status: 'created' | 'accepted' | 'in_progress' | 'completed' | 'cancelled' | 'disputed';
  budgetAmount: number;
  finalAmount: number | null;
  clientId: string;
  contractorId: string | null;
  client?: {
    id: string;
    name: string;
    email: string;
  };
  contractor?: {
    id: string;
    name: string;
    email: string;
  } | null;
  address: string;
  createdAt: string;
  completedAt: string | null;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// Dispute types
export interface Dispute extends Task {
  cancellationReason: string | null;
}

export interface DisputeDetails extends Dispute {
  messages: {
    id: string;
    senderId: string;
    content: string;
    createdAt: string;
  }[];
}

export type DisputeResolution = 'refund' | 'pay_contractor' | 'split';

// Task API functions
export const tasksApi = {
  getAll: (params?: {
    status?: string;
    category?: string;
    page?: number;
    limit?: number;
  }): Promise<PaginatedResponse<Task>> => {
    const searchParams = new URLSearchParams();
    if (params?.status) searchParams.set('status', params.status);
    if (params?.category) searchParams.set('category', params.category);
    if (params?.page) searchParams.set('page', params.page.toString());
    if (params?.limit) searchParams.set('limit', params.limit.toString());

    const query = searchParams.toString();
    return apiFetch(`/admin/tasks${query ? `?${query}` : ''}`);
  },
};

// Disputes API functions
export const disputesApi = {
  getAll: (params?: {
    page?: number;
    limit?: number;
  }): Promise<PaginatedResponse<Dispute>> => {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.set('page', params.page.toString());
    if (params?.limit) searchParams.set('limit', params.limit.toString());

    const query = searchParams.toString();
    return apiFetch(`/admin/disputes${query ? `?${query}` : ''}`);
  },

  getById: (id: string): Promise<DisputeDetails> => {
    return apiFetch(`/admin/disputes/${id}`);
  },

  resolve: (
    id: string,
    resolution: DisputeResolution,
    notes: string
  ): Promise<Task> => {
    return apiFetch(`/admin/disputes/${id}/resolve`, {
      method: 'PUT',
      body: JSON.stringify({ resolution, notes }),
    });
  },
};

// Dashboard API (for future use)
export const dashboardApi = {
  getMetrics: () => apiFetch('/admin/dashboard'),
};

const api = {
  tasks: tasksApi,
  disputes: disputesApi,
  dashboard: dashboardApi,
};

export default api;
