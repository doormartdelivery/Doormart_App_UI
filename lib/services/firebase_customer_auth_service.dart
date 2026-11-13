import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseCustomerAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();

  Future<UserCredential> signInEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<UserCredential> registerEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<UserCredential> signInGoogle() async {
    if (kIsWeb) {
      return _auth.signInWithPopup(GoogleAuthProvider());
    }
    GoogleSignInAccount? account;
    try {
      account = await _google.signIn();
    } on PlatformException catch (error) {
      if (error.code == '10' ||
          error.code.toLowerCase().contains('developer')) {
        throw StateError(
          'Google Sign-In is not configured for this Android build. Add this app SHA-1 in Firebase, download the updated google-services.json, then rebuild.',
        );
      }
      rethrow;
    }
    if (account == null) throw StateError('Google sign-in was cancelled');
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No Firebase account is signed in');
    await user.sendEmailVerification();
  }

  Future<void> reload() async => _auth.currentUser?.reload();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<String> idToken() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Firebase sign-in is required');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty)
      throw StateError('Unable to verify Firebase sign-in');
    return token;
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}
