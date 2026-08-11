import 'session.dart';

abstract class AuthRepository {
  Future<void> requestOtp(String phone);

  Future<Session> verifyOtp({required String phone, required String code});

  Future<void> requestEmailOtp(String email) async {}

  Future<Session> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    throw UnimplementedError();
  }

  Future<Session> loginAsGuest() async {
    throw UnimplementedError();
  }
}
