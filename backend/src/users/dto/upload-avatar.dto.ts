/**
 * Upload Avatar DTO
 * Data transfer object for avatar upload response
 */
export class UploadAvatarResponseDto {
  avatarUrl: string;
  message: string;
}

/**
 * Supported image MIME types
 */
export const ALLOWED_AVATAR_MIMETYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
];

/**
 * Maximum file size in bytes (5MB)
 */
export const MAX_AVATAR_SIZE = 5 * 1024 * 1024;
