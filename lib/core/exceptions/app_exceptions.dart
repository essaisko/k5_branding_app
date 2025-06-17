/// 앱 전체에서 사용하는 예외 클래스들
/// 비즈니스 로직과 에러 처리를 명확히 분리

/// 기본 앱 예외 클래스
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message';
}

/// 인증 관련 예외
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'AuthException: $message';
}

/// 스토리지 관련 예외
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'StorageException: $message';
}

/// 네트워크 관련 예외
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'NetworkException: $message';
}

/// 데이터베이스 관련 예외
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'DatabaseException: $message';
}

/// 검증 관련 예외
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'ValidationException: $message';
}

/// 권한 관련 예외
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'PermissionException: $message';
}
