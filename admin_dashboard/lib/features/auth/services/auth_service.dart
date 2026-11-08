import 'package:firebase_auth/firebase_auth.dart';

/// Minimal Firebase Auth wrapper for the dashboard.
///
/// The Nov 8 school MVP does not use custom claims or Cloud Functions, so any
/// verified signed-in Firebase user can open the admin studio. Production
/// deployments should replace [isStaff] with a custom claim or an allow-list.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  bool get isStaff => _auth.currentUser != null;

  Future<bool> isAdmin() async => isStaff;
}
