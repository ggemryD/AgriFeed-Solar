import 'package:flutter/foundation.dart';

import '../model/user_model.dart';
import '../repository/auth_repository.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository) {
    _init();
  }

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.checking;
  bool _isBusy = false;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  bool get isBusy => _isBusy;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> _init() async {
    try {
      final currentUser = await _repository.getCurrentUser();
      if (currentUser != null) {
        _user = currentUser;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
      _errorMessage = null;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Authentication initialization failed';
      if (kDebugMode) {
        print('Auth init error: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setBusy(true);
    try {
      _errorMessage = null;
      final signedInUser = await _repository.signIn(
        email: email,
        password: password,
      );
      _user = signedInUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on StateError catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (error) {
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      if (kDebugMode) {
        print('Sign in error: $error');
      }
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    String? farmName,
    String? location,
  }) async {
    _setBusy(true);
    try {
      _errorMessage = null;
      final createdUser = await _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
        farmName: farmName,
        location: location,
      );
      _user = createdUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on StateError catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (error) {
      _errorMessage = 'Could not create the account. Please try again later.';
      notifyListeners();
      if (kDebugMode) {
        print('Sign up error: $error');
      }
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setBusy(true);
    try {
      _errorMessage = null;
      final signedInUser = await _repository.signInWithGoogle();
      _user = signedInUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = 'Google sign in failed. Please try again later.';
      notifyListeners();
      if (kDebugMode) {
        print('Google sign in error: $error');
      }
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    _setBusy(true);
    try {
      await _repository.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? farmName,
    String? location,
    String? machineId,
    String? photoUrl,
  }) async {
    final currentUser = _user;
    if (currentUser == null) {
      _errorMessage = 'No active session. Please sign in again.';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    try {
      _errorMessage = null;
      final updatedUser = await _repository.updateProfile(
        user: currentUser,
        fullName: fullName,
        farmName: farmName,
        location: location,
        machineId: machineId,
        photoUrl: photoUrl,
      );
      _user = updatedUser;
      notifyListeners();
      return true;
    } on StateError catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (error) {
      _errorMessage = 'Could not update profile. Please try again later.';
      notifyListeners();
      if (kDebugMode) {
        print('Update profile error: $error');
      }
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> changePassword({required String newPassword}) async {
    _setBusy(true);
    try {
      _errorMessage = null;
      await _repository.changePassword(newPassword: newPassword);
      _errorMessage = null;
      notifyListeners();
      return true;
    } on StateError catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (error) {
      _errorMessage = 'Unable to change password right now.';
      notifyListeners();
      if (kDebugMode) {
        print('Change password error: $error');
      }
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> reloadCurrentUser() async {
    try {
      final refreshedUser = await _repository.getCurrentUser();
      if (refreshedUser == null) {
        _user = null;
        _status = AuthStatus.unauthenticated;
      } else {
        _user = refreshedUser;
      }
    } catch (error) {
      if (kDebugMode) {
        print('Reload current user error: $error');
      }
    } finally {
      notifyListeners();
    }
  }

  void _setBusy(bool value) {
    if (_isBusy != value) {
      _isBusy = value;
      notifyListeners();
    }
  }
}
