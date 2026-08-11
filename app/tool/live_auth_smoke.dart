import 'package:local_lens/core/network/api_client.dart';
import 'package:local_lens/features/auth/data/auth_api.dart';

Future<void> main() async {
  final client = ApiClient(
    baseUrl: 'http://127.0.0.1:8000/api/v1',
    accessTokenProvider: () => null,
  );
  final api = AuthApi(client);

  // 1. Guest login
  final guest = await api.loginAsGuest();
  print('GUEST OK -> isGuest=${guest.isGuest} userId=${guest.userId}');

  // 2. OTP request
  await api.requestOtp('+919876543210');
  print('OTP REQUEST OK');

  // 3. Verify with master code 000000
  final session = await api.verifyOtp(phone: '+919876543210', code: '000000');
  print(
    'OTP VERIFY OK -> userId=${session.userId} '
    'anonId=${session.anonId} tokenLen=${session.accessToken.length}',
  );
}
