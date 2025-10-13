import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '785080321235-082n987sijag11h65enektf4k6lcs571.apps.googleusercontent.com',
  );

  Future<User?> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  ///  chỉ reset nếu user dùng phương thức Email/Password
  Future<void> resetPassword(String email) async {
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    if (methods.contains('password')) {
      await _auth.sendPasswordResetEmail(email: email);
    } else {
      throw FirebaseAuthException(
        code: 'google-account',
        message: 'Tài khoản này đăng nhập bằng Google, không cần đặt lại mật khẩu.',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final isSignedIn = await _googleSignIn.isSignedIn();
    if (isSignedIn) {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
    }
  }

  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
}
