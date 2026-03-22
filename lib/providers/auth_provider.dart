import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isNurse => _currentUser?.isNurse ?? false;
  bool get isDoctor => _currentUser?.isDoctor ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isPatient => _currentUser?.isPatient ?? false;

  AuthService get authService => _authService;
  String? get accessToken => _authService.accessToken;

  Future<void> initialize() async {
    try {
      final loggedIn = await _authService.isLoggedIn();
      if (loggedIn) {
        if (_authService.accessToken != null) {
          DatabaseService.setGlobalToken(_authService.accessToken!);
        }
        _currentUser = await _authService.getUserData();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      if (_authService.accessToken != null) {
        DatabaseService.setGlobalToken(_authService.accessToken!);
      }
      _currentUser = await _authService.getUserData();
      await _authService.updateUserStatus(isOnline: true);
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String role,
    String? assignedWard,
    String? specialization,
    String? patientId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        employeeId: employeeId,
        role: role,
        assignedWard: assignedWard,
        specialization: specialization,
        patientId: patientId,
      );
      if (_authService.accessToken != null) {
        DatabaseService.setGlobalToken(_authService.accessToken!);
      }
      _currentUser = await _authService.getUserData();
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.updateUserStatus(isOnline: false);
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _currentUser = await _authService.getUserData();
    notifyListeners();
  }

  Future<List<UserModel>> getAllDoctors() => _authService.getAllDoctors();
  Future<List<UserModel>> getAllNurses() => _authService.getAllNurses();

  String _parseError(String error) {
    final msg = error.replaceFirst('Exception: ', '');
    if (msg.contains('401') || msg.contains('Invalid')) return 'Invalid email or password';
    if (msg.contains('400') || msg.contains('already')) return 'Email already registered';
    if (msg.contains('Connection')) return 'Cannot connect to server. Is the backend running?';
    return msg;
  }
}
