import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  // Allowed credentials
  final String allowedEmail = 'praveen@gmail.com';
  final String allowedPassword = '123456';
  String? _loggedInEmail;

  bool get isLoggedIn => _loggedInEmail != null;
  String? get currentUser => _loggedInEmail;

  // Login
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == allowedEmail && password == allowedPassword) {
      _loggedInEmail = email;
      return true;
    }
    return false;
  }

  // Register (restricted)
  Future<bool> register(String email, String password, String confirmPassword) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == allowedEmail &&
        password == allowedPassword &&
        password == confirmPassword) {
      _loggedInEmail = email;
      return true;
    }
    return false;
  }

  // Logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _loggedInEmail = null;
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthStateNotifier, bool>((ref) {
  final auth = ref.watch(authServiceProvider);
  return AuthStateNotifier(auth);
});

class AuthStateNotifier extends StateNotifier<bool> {
  final AuthService _auth;
  AuthStateNotifier(this._auth) : super(_auth.isLoggedIn);

  Future<bool> login(String email, String password) async {
    final success = await _auth.login(email, password);
    state = _auth.isLoggedIn;
    return success;
  }

  Future<bool> register(String email, String password, String confirmPassword) async {
    final success = await _auth.register(email, password, confirmPassword);
    state = _auth.isLoggedIn;
    return success;
  }

  Future<void> logout() async {
    await _auth.logout();
    state = _auth.isLoggedIn;
  }
}
