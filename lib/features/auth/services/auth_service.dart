import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../auth/model/user_model.dart';
import '../../../core/services/firebase_service.dart';

class AuthService {
  final FirebaseService _firebaseService;

  AuthService(this._firebaseService);

  User? get currentUser => _firebaseService.currentUser;

  Stream<User?> get authStateChanges => _firebaseService.authStateChanges;

  Future<UserModel> signInWithGoogle() async {
    final userCredential = await _firebaseService.signInWithGoogle();
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Failed to retrieve user after Google sign-in');
    }

    // Fetch the actual user data from Firebase to get farmName, location, etc.
    final userData = await _firebaseService.getUserData(user.uid);

    return UserModel(
      id: user.uid,
      fullName: userData?['displayName'] ?? user.displayName ?? 'Google User',
      email: user.email ?? '',
      farmName: userData?['farmName'],
      location: userData?['location'],
      machineId: userData?['machineId'],
      photoUrl: user.photoURL,
    );
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = FirebaseAuth.instance;
    final userCredential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Failed to retrieve user after sign-in');
    }

    final userData = await _firebaseService.getUserData(user.uid);

    return UserModel(
      id: user.uid,
      fullName: userData?['displayName'] ?? user.email?.split('@')[0] ?? 'User',
      email: user.email ?? '',
      farmName: userData?['farmName'],
      location: userData?['location'],
      machineId: userData?['machineId'],
      photoUrl: user.photoURL,
    );
  }

  Future<UserModel> createUserWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
    String? farmName,
    String? location,
  }) async {
    final auth = FirebaseAuth.instance;
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: email, 
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Failed to create user');
    }

    await user.updateDisplayName(fullName);

    final userData = {
      'displayName': fullName,
      'email': email,
      'farmName': farmName,
      'location': location,
      'machineId': 'ATS-${DateTime.now().millisecondsSinceEpoch % 1000}',
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _firebaseService.updateUserData(user.uid, userData);

    return UserModel(
      id: user.uid,
      fullName: fullName,
      email: email,
      farmName: farmName,
      location: location,
      machineId: userData['machineId'],
      photoUrl: user.photoURL,
    );
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseService.currentUser;
    if (user == null) return null;

    final userData = await _firebaseService.getUserData(user.uid);

    return UserModel(
      id: user.uid,
      fullName: userData?['displayName'] ?? user.displayName ?? 'User',
      email: user.email ?? '',
      farmName: userData?['farmName'],
      location: userData?['location'],
      machineId: userData?['machineId'],
      photoUrl: user.photoURL,
    );
  }

  Future<UserModel> updateProfile({
    required UserModel user,
    String? fullName,
    String? farmName,
    String? location,
    String? machineId,
    String? photoUrl,
  }) async {
    final updateData = <String, dynamic>{};

    if (fullName != null) updateData['displayName'] = fullName;
    if (farmName != null) updateData['farmName'] = farmName;
    if (location != null) updateData['location'] = location;
    if (machineId != null) updateData['machineId'] = machineId;

    if (updateData.isNotEmpty) {
      await _firebaseService.updateUserData(user.id, updateData);
    }

    if (fullName != null && fullName != user.fullName) {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(fullName);
    }

    return user.copyWith(
      fullName: fullName,
      farmName: farmName,
      location: location,
      machineId: machineId,
      photoUrl: photoUrl,
    );
  }

  Future<void> changePassword({required String newPassword}) async {
    await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
  }
}
