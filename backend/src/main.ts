/**
 * Main Entry Point
 * Szybka Fucha Backend API
 */
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    rawBody: true, // Enable raw body for Stripe webhooks
  });

  // Get config service
  const configService = app.get(ConfigService);

  // Enable CORS for mobile app, admin dashboard, and landing page
  const allowedOrigins = [
    configService.get<string>('FRONTEND_URL', 'http://localhost:3001'),
    configService.get<string>('ADMIN_URL', 'http://localhost:3002'),
    'http://localhost:8080', // Landing page (development)
    configService.get<string>('LANDING_PAGE_URL'), // Landing page (production)
  ].filter(Boolean); // Remove undefined values

  app.enableCors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, Postman, etc.)
      if (!origin) {
        return callback(null, true);
      }
      
      // Check if origin is in allowed list
      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      
      // In production, allow same-origin requests
      const isProduction = configService.get<string>('NODE_ENV') === 'production';
      if (isProduction) {
        // Allow requests from same domain (for landing page on same domain)
        return callback(null, true);
      }
      
      callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
  });

  // Global validation pipe with class-validator
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strip unknown properties
      forbidNonWhitelisted: true, // Throw error on unknown properties
      transform: true, // Auto-transform payloads to DTO instances
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Set global API prefix
  const apiPrefix = configService.get<string>('API_PREFIX', 'api/v1');
  app.setGlobalPrefix(apiPrefix);

  // Start server
  const port = configService.get<number>('PORT', 3000);
  await app.listen(port);

  console.log(`
  🚀 Szybka Fucha API is running!
  
  📍 Local:    http://localhost:${port}/${apiPrefix}
  📍 Health:   http://localhost:${port}/${apiPrefix}/health
  
  📚 Auth endpoints:
     POST /${apiPrefix}/auth/phone/request-otp
     POST /${apiPrefix}/auth/phone/verify
     POST /${apiPrefix}/auth/google
     POST /${apiPrefix}/auth/apple
  `);
}

bootstrap();
