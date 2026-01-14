/**
 * KYC DTOs
 * Validation and types for KYC operations
 */
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  Matches,
} from 'class-validator';

// Document types supported by Onfido
export enum DocumentType {
  PASSPORT = 'passport',
  NATIONAL_ID = 'national_identity_card',
  DRIVING_LICENCE = 'driving_licence',
  RESIDENCE_PERMIT = 'residence_permit',
}

// KYC check types
export enum KycCheckType {
  DOCUMENT = 'document',
  FACIAL_SIMILARITY = 'facial_similarity_photo',
}

// Upload ID document DTO
export class UploadIdDocumentDto {
  @IsEnum(DocumentType)
  documentType: DocumentType;

  // Base64 encoded image or file URL
  @IsString()
  @IsNotEmpty()
  documentFront: string;

  @IsString()
  @IsOptional()
  documentBack?: string; // Required for some document types

  @IsString()
  @IsOptional()
  issuingCountry?: string;
}

// Upload selfie DTO
export class UploadSelfieDto {
  // Base64 encoded image
  @IsString()
  @IsNotEmpty()
  selfieImage: string;
}

// Verify bank account DTO
export class VerifyBankDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^[A-Z]{2}[0-9]{2}[A-Z0-9]{4,30}$/, {
    message: 'Invalid IBAN format',
  })
  iban: string;

  @IsString()
  @IsNotEmpty()
  accountHolderName: string;

  @IsString()
  @IsOptional()
  bankName?: string;
}

// KYC status response
export interface KycStatusResponse {
  userId: string;
  overallStatus: 'pending' | 'verified' | 'rejected';
  idVerified: boolean;
  selfieVerified: boolean;
  bankVerified: boolean;
  checks: {
    id: string;
    type: string;
    status: string;
    result: string | null;
    createdAt: Date;
  }[];
  canAcceptTasks: boolean;
}

// Onfido webhook payload type
export interface OnfidoWebhookPayload {
  payload: {
    resource_type: string;
    action: string;
    object: {
      id: string;
      status: string;
      result: string;
      sub_result?: string;
      href: string;
    };
  };
}
