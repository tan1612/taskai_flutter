import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    required this.isLoading,
    this.errorMessage,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState(isLoading: false)) {
    _repository.authStateChanges.listen((user) {
      state = AuthState(user: user, isLoading: false);
    });
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signInWithEmailAndPassword(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'Đăng nhập thất bại';
      if (e.code == 'user-not-found') {
        msg = 'Không tìm thấy tài khoản với email này';
      } else if (e.code == 'wrong-password') {
        msg = 'Mật khẩu không chính xác';
      } else if (e.code == 'invalid-email') {
        msg = 'Email không hợp lệ';
      } else if (e.message != null) {
        msg = e.message!;
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signUpWithEmailAndPassword(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'Đăng ký thất bại';
      if (e.code == 'email-already-in-use') {
        msg = 'Email này đã được sử dụng';
      } else if (e.code == 'weak-password') {
        msg = 'Mật khẩu quá yếu';
      } else if (e.code == 'invalid-email') {
        msg = 'Email không hợp lệ';
      } else if (e.message != null) {
        msg = e.message!;
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _repository.signOut();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final guestModeProvider = StateProvider<bool>((ref) {
  return false;
});
