import '../../../core/network/api_exceptions.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

class AuthMock implements AuthRepository {
  AuthMock({this.acceptedCode = '000000'});

  final String acceptedCode;

  @override
  Future<void> requestOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<Session> verifyOtp({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (code != acceptedCode) {
      throw ApiServerException(
        statusCode: 400,
        code: 'otp_invalid',
        message: 'OTP is invalid or expired',
      );
    }
    return const Session(accessToken: 'mock-access-token', userId: 1);
  }

  @override
  Future<void> requestEmailOtp(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<Session> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (code != acceptedCode) {
      throw ApiServerException(
        statusCode: 400,
        code: 'otp_invalid',
        message: 'OTP is invalid or expired',
      );
    }
    return const Session(accessToken: 'mock-email-token', userId: 1);
  }

  @override
  Future<Session> loginAsGuest() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const Session(
      accessToken: 'mock-guest-token',
      userId: 'guest:mock',
      isGuest: true,
    );
  }
}
