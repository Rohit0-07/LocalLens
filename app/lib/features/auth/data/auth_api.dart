import '../../../core/network/api_client.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

class AuthApi implements AuthRepository {
  AuthApi(this._client);

  final ApiClient _client;

  @override
  Future<void> requestOtp(String phone) async {
    await _client.postJson(
      '/auth/otp/request',
      body: {'phone': phone},
      expectNoContent: true,
    );
  }

  @override
  Future<Session> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final data = await _client.postJson(
      '/auth/otp/verify',
      body: {'phone': phone, 'code': code},
    );
    return Session.fromJson(data as Map<String, Object?>);
  }

  @override
  Future<void> requestEmailOtp(String email) async {
    await _client.postJson(
      '/auth/email/request-otp',
      body: {'email': email},
      expectNoContent: true,
    );
  }

  @override
  Future<Session> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    final data = await _client.postJson(
      '/auth/email/verify-otp',
      body: {'email': email, 'code': code},
    );
    return Session.fromJson(data as Map<String, Object?>);
  }

  @override
  Future<Session> loginAsGuest() async {
    final data = await _client.postJson('/auth/guest');
    return Session.fromJson(data as Map<String, Object?>);
  }
}
