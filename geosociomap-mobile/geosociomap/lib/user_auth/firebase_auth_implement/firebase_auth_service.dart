import 'package:firebase_auth/firebase_auth.dart';
import 'package:geosociomap/components/toast.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> getCurrentUserUid() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showToast(message: 'The email address is already in use.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        showToast(message: 'Invalid email or password.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }

  Future<void> deleteUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await user.delete();
        print('User deleted successfully');
      } catch (e) {
        print('Error deleting user: $e');
      }
    }
  }

  Future<void> sendEmailVerificationLink() async {
    try {
      _auth.currentUser?.sendEmailVerification();
      showToast(message: 'Email verification sent!');
    } on FirebaseAuthException catch (e) {
      showToast(message: e.message!); // Display error message
    }
  }

  // Future<void> reauthenticateAndDelete() async {
  //   try {
  //     final providerData = _auth.currentUser?.providerData.first;

  //     if (AppleAuthProvider().providerId == providerData!.providerId) {
  //       await _auth.currentUser!
  //           .reauthenticateWithProvider(AppleAuthProvider());
  //     } else if (GoogleAuthProvider().providerId == providerData.providerId) {
  //       await _auth.currentUser!
  //           .reauthenticateWithProvider(GoogleAuthProvider());
  //     }

  //     await _auth.currentUser?.delete();
  //   } catch (e) {
  //     showToast(message: 'An error occurred: ${e}');
  //   }
  // }
}
