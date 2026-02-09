import 'dart:async';

import '../model/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<UserModel?> getCurrentUser() async {
    return await _authService.getCurrentUser();
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    return await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    String? farmName,
    String? location,
  }) async {
    return await _authService.createUserWithEmailAndPassword(
      fullName: fullName,
      email: email,
      password: password,
      farmName: farmName,
      location: location,
    );
  }

  Future<UserModel> signInWithGoogle() async {
    return await _authService.signInWithGoogle();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<UserModel> updateProfile({
    required UserModel user,
    String? fullName,
    String? farmName,
    String? location,
    String? machineId,
    String? photoUrl,
  }) async {
    return await _authService.updateProfile(
      user: user,
      fullName: fullName,
      farmName: farmName,
      location: location,
      machineId: machineId,
      photoUrl: photoUrl,
    );
  }

  Future<void> changePassword({required String newPassword}) async {
    await _authService.changePassword(newPassword: newPassword);
  }
}
