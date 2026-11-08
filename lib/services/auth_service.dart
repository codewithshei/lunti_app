import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service to handle user state
class AuthService {
  /// Resolved lazily so screens can be built (and previewed/tested) before
  /// `Firebase.initializeApp` has run. Only real auth calls need Firebase.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Stream of the current user
  Stream<User?> get user => _auth.authStateChanges();

  /// Current signed in user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() {
    return _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Human-friendly copy for the auth errors users are most likely to hit.
  static String friendlyMessage(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'That email address does not look right.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already uses this email. Try signing in.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      default:
        return exception.message ?? 'Authentication failed. Please try again.';
    }
  }
}
