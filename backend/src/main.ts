/**
 * Main Entry Point
 * Szybka Fucha Backend API
 */
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Get config service
  const configService = app.get(ConfigService);

  // Enable CORS for mobile app and admin dashboard
  app.enableCors({
    origin: [
      configService.get<string>('FRONTEND_URL', 'http://localhost:3001'),
      configService.get<string>('ADMIN_URL', 'http://localhost:3002'),
    ],
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
