/**
 * CategoryPricing Entity
 * Stores pricing information for task categories (min, max, suggested prices)
 * Managed through admin panel, consumed by mobile app
 */
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('category_pricing')
export class CategoryPricing {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Category key matching TaskCategory enum
   * e.g., 'paczki', 'hydraulik', 'sprzatanie'
   */
  @Column({ type: 'varchar', length: 50, unique: true })
  category: string;

  /**
   * Minimum suggested price in PLN
   * Must be >= 35 (platform minimum)
   */
  @Column({ type: 'int' })
  minPrice: number;

  /**
   * Maximum suggested price in PLN
   * Must be > minPrice
   */
  @Column({ type: 'int' })
  maxPrice: number;

  /**
   * Suggested price in PLN
   * If null, calculated as (minPrice + maxPrice) / 2
   */
  @Column({ type: 'int', nullable: true })
  suggestedPrice: number | null;

  /**
   * Price unit for display
   * 'PLN' for flat rate, 'PLN/h' for hourly rate
   */
  @Column({ type: 'varchar', length: 10, default: 'PLN' })
  priceUnit: string;

  /**
   * Estimated task duration in minutes
   * Used for time estimates in mobile app
   */
  @Column({ type: 'int' })
  estimatedMinutes: number;

  /**
   * Whether this category pricing is active
   * Inactive categories won't be returned to mobile app
   */
  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  /**
   * Get the effective suggested price
   * Returns suggestedPrice if set, otherwise calculates average
   */
  getEffectiveSuggestedPrice(): number {
    if (this.suggestedPrice !== null) {
      return this.suggestedPrice;
    }
    return Math.round((this.minPrice + this.maxPrice) / 2);
  }
}
