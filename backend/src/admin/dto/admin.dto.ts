/**
 * Admin DTOs and Interfaces
 * Types for admin dashboard API
 */
import { User } from '../../users/entities/user.entity';
import { Task } from '../../tasks/entities/task.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { Rating } from '../../tasks/entities/rating.entity';
import { ContractorProfile } from '../../contractor/entities/contractor-profile.entity';

// Dashboard metrics interface
export interface DashboardMetrics {
  users: {
    total: number;
    clients: number;
    contractors: number;
    newToday: number;
    newThisWeek: number;
  };
  tasks: {
    total: number;
    today: number;
    thisWeek: number;
    thisMonth: number;
    byStatus: Record<string, number>;
    averageCompletionTimeMinutes: number | null;
  };
  revenue: {
    totalGmv: number;
    totalRevenue: number;
    gmvToday: number;
    revenueToday: number;
    gmvThisWeek: number;
    revenueThisWeek: number;
    gmvThisMonth: number;
    revenueThisMonth: number;
  };
  disputes: {
    total: number;
    pending: number;
  };
}

// Paginated response interface
export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

// User with optional contractor profile
export interface UserWithProfile extends User {
  contractorProfile?: ContractorProfile;
}

// Dispute details response
export interface DisputeDetails {
  task: Task;
  payments: Payment[];
  ratings: Rating[];
}

// Contractor stats response
export interface ContractorStats {
  profile: ContractorProfile | null;
  completedTasks: number;
  earnings: number;
  averageRating: number;
  recentTasks: Task[];
}

// Dispute resolution types
export type DisputeResolution = 'refund' | 'pay_contractor' | 'split';
