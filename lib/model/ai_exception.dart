import 'dart:convert';

enum AiErrorType {
  invalidRequest,
  authFailed,
  notFound,
  rateLimited,
  serverError,
  serviceUnavailable,
  deadlineExceeded,
  badResponse,
  unknown,
}

class AiException implements Exception {
  final AiErrorType type;
  final String message;
  final bool retryable;
  final int? statusCode;

  const AiException({
    required this.type,
    required this.message,
    this.retryable = false,
    this.statusCode,
  });

  factory AiException.fromStatusCode(int code, String body) {
    final providerMessage = _messageFromResponseBody(body);
    switch (code) {
      case 400:
        return AiException(
          type: AiErrorType.invalidRequest,
          message: providerMessage == null
              ? 'Invalid request. The request payload may be malformed. ($code)'
              : 'Invalid request: $providerMessage ($code)',
          statusCode: code,
        );
      case 401:
      case 403:
        return AiException(
          type: AiErrorType.authFailed,
          message: providerMessage == null
              ? 'Invalid API key. Check your settings. ($code)'
              : 'Authentication failed: $providerMessage ($code)',
          statusCode: code,
        );
      case 404:
        return AiException(
          type: AiErrorType.notFound,
          message: providerMessage == null
              ? 'Model not found. Try a different model. ($code)'
              : 'Model not found: $providerMessage ($code)',
          statusCode: code,
        );
      case 429:
        return AiException(
          type: AiErrorType.rateLimited,
          message: providerMessage == null
              ? 'Rate limit exceeded. Please retry once the limit resets. ($code)'
              : 'Rate limit exceeded: $providerMessage ($code)',
          statusCode: code,
        );
      case 500:
        return AiException(
          type: AiErrorType.serverError,
          message: providerMessage == null
              ? 'Server error. Retrying... ($code)'
              : 'Server error: $providerMessage ($code)',
          retryable: true,
          statusCode: code,
        );
      case 503:
        return AiException(
          type: AiErrorType.serviceUnavailable,
          message: providerMessage == null
              ? 'Service temporarily unavailable. Retrying... ($code)'
              : 'Service temporarily unavailable: $providerMessage ($code)',
          retryable: true,
          statusCode: code,
        );
      case 504:
        return AiException(
          type: AiErrorType.deadlineExceeded,
          message: providerMessage == null
              ? 'Request timed out. Retrying... ($code)'
              : 'Request timed out: $providerMessage ($code)',
          retryable: true,
          statusCode: code,
        );
      default:
        return AiException(
          type: AiErrorType.unknown,
          message: providerMessage == null
              ? 'Unexpected error occurred. ($code)'
              : 'Unexpected error: $providerMessage ($code)',
          statusCode: code,
        );
    }
  }

  @override
  String toString() => message;
}

String? _messageFromResponseBody(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;

    final error = decoded['error'];
    if (error is Map) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    final message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  } catch (_) {
    return null;
  }
  return null;
}
