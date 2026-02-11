import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in aborted by user');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      await _saveUserToDatabase(userCredential.user);

      return userCredential;
    } catch (e) {
      log('Google sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
    } catch (e) {
      log('Sign-out error: $e');
      rethrow;
    }
  }

  Future<void> _saveUserToDatabase(User? user) async {
    if (user == null) return;

    final userRef = _database.child('users').child(user.uid);
    
    // First, get existing user data to preserve farmName and location
    final existingData = await getUserData(user.uid);
    
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'lastSignIn': ServerValue.timestamp,
      // Preserve existing profile data if it exists
      'farmName': existingData?['farmName'] ?? user.displayName,
      'location': existingData?['location'] ?? null,
      'machineId': existingData?['machineId'] ?? 'ATS-${DateTime.now().millisecondsSinceEpoch % 1000}',
      'createdAt': existingData?['createdAt'] ?? ServerValue.timestamp,
    };

    await userRef.update(userData);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final DataSnapshot snapshot =
          await _database.child('users').child(uid).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      log('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _database.child('users').child(uid).update(data);
    } catch (e) {
      log('Error updating user data: $e');
      rethrow;
    }
  }

  DatabaseReference get databaseRef => _database;
}
