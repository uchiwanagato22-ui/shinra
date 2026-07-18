import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Couche d'authentification Shinra IA.
/// Toute la logique de compte (email/mot de passe + Google) passe par ici,
/// pour que le reste de l'app n'ait jamais à parler directement à Firebase.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool get isLoggedIn => _auth.currentUser != null;

  /// Inscription par email/mot de passe.
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
      }
      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_messageFromCode(e.code));
    } catch (e) {
      return AuthResult.failure('Erreur inconnue : $e');
    }
  }

  /// Connexion par email/mot de passe.
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_messageFromCode(e.code));
    } catch (e) {
      return AuthResult.failure('Erreur inconnue : $e');
    }
  }

  /// Connexion via Google (compte utilisé aussi pour le futur mode Pro).
  static Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('Connexion Google annulée.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return AuthResult.success(userCredential.user);
    } catch (e) {
      return AuthResult.failure('Erreur connexion Google : $e');
    }
  }

  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null, message: 'Email de réinitialisation envoyé.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_messageFromCode(e.code));
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Jeton d'identité Firebase : c'est CE jeton (pas une clé API) qui sera
  /// envoyé au futur backend Pro pour vérifier qui fait la requête.
  static Future<String?> getIdToken() async {
    return _auth.currentUser?.getIdToken();
  }

  static String _messageFromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Aucun compte pour cet email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum).';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      default:
        return 'Erreur d\'authentification ($code).';
    }
  }
}

class AuthResult {
  final bool ok;
  final User? user;
  final String? message;

  AuthResult._(this.ok, this.user, this.message);

  factory AuthResult.success(User? user, {String? message}) => AuthResult._(true, user, message);
  factory AuthResult.failure(String message) => AuthResult._(false, null, message);
}
