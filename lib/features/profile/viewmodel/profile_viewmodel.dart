import 'package:flutter/foundation.dart';

import '../../auth/model/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._authViewModel) {
    _authViewModel.addListener(_onAuthChanged);
  }

  final AuthViewModel _authViewModel;

  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _isLoggingOut = false;
  String? _errorMessage;

  UserModel? get user => _authViewModel.user;
  bool get isSavingProfile => _isSavingProfile;
  bool get isChangingPassword => _isChangingPassword;
  bool get isLoggingOut => _isLoggingOut;
  bool get isBusy => _isSavingProfile || _isChangingPassword || _isLoggingOut;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<bool> updateProfile({
    String? fullName,
    String? farmName,
    String? location,
    String? machineId,
    String? photoUrl,
  }) async {
    _setSaving(true);
    try {
      final success = await _authViewModel.updateProfile(
        fullName: fullName,
        farmName: farmName,
        location: location,
        machineId: machineId,
        photoUrl: photoUrl,
      );
      if (!success) {
        _errorMessage = _authViewModel.errorMessage;
      } else {
        _errorMessage = null;
      }
      notifyListeners();
      return success;
    } finally {
      _setSaving(false);
    }
  }

  Future<bool> changePassword(String newPassword) async {
    _setChangingPassword(true);
    try {
      final success = await _authViewModel.changePassword(
        newPassword: newPassword,
      );
      if (!success) {
        _errorMessage = _authViewModel.errorMessage;
      } else {
        _errorMessage = null;
      }
      notifyListeners();
      return success;
    } finally {
      _setChangingPassword(false);
    }
  }

  Future<void> logout() async {
    _setLoggingOut(true);
    try {
      await _authViewModel.signOut();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to logout';
    } finally {
      _setLoggingOut(false);
    }
  }

  Future<void> signOut() async {
    await logout();
  }

  void _onAuthChanged() {
    notifyListeners();
  }

  void _setSaving(bool value) {
    if (_isSavingProfile != value) {
      _isSavingProfile = value;
      notifyListeners();
    }
  }

  void _setChangingPassword(bool value) {
    if (_isChangingPassword != value) {
      _isChangingPassword = value;
      notifyListeners();
    }
  }

  void _setLoggingOut(bool value) {
    if (_isLoggingOut != value) {
      _isLoggingOut = value;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthChanged);
    super.dispose();
  }
}
