import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Internal server error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'string') {
        message = exceptionResponse;
      } else if (
        typeof exceptionResponse === 'object' &&
        exceptionResponse !== null
      ) {
        const responseMessage =
          'message' in exceptionResponse
            ? (exceptionResponse as { message?: string | string[] }).message
            : undefined;
        message = responseMessage ?? message;
      }
    }

    // Log error with stack trace
    this.logger.error(
      `${request.method} ${request.url} - ${status} - ${JSON.stringify(message)}`,
      exception instanceof Error ? exception.stack : '',
    );

    // Consistent response format
    response.status(status).json({
      success: false,
      message: Array.isArray(message) ? message : [message],
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
