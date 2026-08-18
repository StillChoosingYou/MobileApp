/// Centralized path strings so screens never hardcode a route.
class Routes {
  Routes._();

  static const intro = '/intro';
  static const roleSelect = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const twoFactor = '/2fa';

  static const student = '/student';
  static const registrar = '/registrar';
  static const cashier = '/cashier';
  static const faculty = '/faculty';
  static const admin = '/admin';

  /// Shared by Accounting, Guidance, Dept Head, and Dean — see
  /// [GenericRoleDashboard] in features/other_roles.
  static const roleDashboard = '/dashboard';

  static const emergency = '/emergency';
  static const visitorPass = '/visitor-pass';
  static const lostFound = '/lost-found';
}
