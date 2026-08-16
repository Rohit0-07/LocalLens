abstract final class RoutePaths {
  static const feed = '/feed';
  static const map = '/map';
  static const reels = '/reels';
  static const inbox = '/inbox';
  static const profile = '/profile';

  static const signIn = '/sign-in';
  static const otp = '/otp';
  static const compose = '/compose';
  static const notifications = '/notifications';
  static const repDashboard = '/rep-dashboard';
  static const issueDetail = '/issue/:id';
  static const anonymityGuide = '/anonymity-guide';
  static const search = '/search';
  static const gamification = '/gamification';
  static const adminFlaggedQueue = '/admin/flagged-queue';
  static const wardDetail = '/ward/:slug';
  static const outbox = '/outbox';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';
  static const publicProfile = '/users/:id';

  static const onboarding = '/onboarding';

  static String issueDetailFor(int id) => '/issue/$id';
  static String wardDetailFor(String slug) => '/ward/$slug';
  static String publicProfileFor(int id) => '/users/$id';
}

