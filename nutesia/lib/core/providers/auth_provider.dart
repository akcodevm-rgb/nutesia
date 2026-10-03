import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;
  bool _isLoading = false;
  bool _isLoginMode = true;
  String? _errorMessage;
  AppError? _appError;

  AuthProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isLoginMode => _isLoginMode;
  String? get errorMessage => _errorMessage;
  AppError? get appError => _appError;

  void toggleMode() {
    _isLoginMode = !_isLoginMode;
    _errorMessage = null;
    _appError = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _appError = null;
    notifyListeners();
  }

  Future<bool> signInAnonymously() async {
    _isLoading = true;
    _errorMessage = null;
    _appError = null;
    notifyListeners();

    try {
      final credential = await _auth.signInAnonymously();
      _user = credential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _appError = AppErrorHandler.parse(e);
      _errorMessage = _appError!.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _appError = ValidationAppError.fromFieldErrors(
        fieldErrors: {
          if (email.trim().isEmpty) 'email': 'Email is required',
          if (password.isEmpty) 'password': 'Password is required',
        },
        message: 'Please enter both email and password',
      );
      _errorMessage = _appError!.message;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _appError = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = credential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _appError = AppErrorHandler.parse(e);
      _errorMessage = _appError!.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _appError = ValidationAppError.fromFieldErrors(
        fieldErrors: {
          if (email.trim().isEmpty) 'email': 'Email is required',
          if (password.isEmpty) 'password': 'Password is required',
        },
        message: 'Please enter both email and password',
      );
      _errorMessage = _appError!.message;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _appError = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = credential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _appError = AppErrorHandler.parse(e);
      _errorMessage = _appError!.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signOut();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
