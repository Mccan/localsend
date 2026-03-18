import 'package:flutter/foundation.dart';
import 'package:linkdrop_app/model/user.dart';
import 'package:linkdrop_app/services/api_service.dart';

/// 认证状态
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? (user != null),
    );
  }
}

/// 认证状态管理
///
/// 使用 ChangeNotifier 管理用户认证状态
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthState _state = const AuthState();
  AuthState get state => _state;

  User? get user => _state.user;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;

  /// 初始化认证状态（应用启动时调用）
  Future<void> initialize() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final token = await _apiService.getAccessToken();
      if (token != null) {
        // 有 token，尝试获取用户信息
        final user = await _apiService.getCurrentUser();
        if (user != null) {
          _state = AuthState(
            user: user,
            isLoading: false,
            isAuthenticated: true,
          );
        } else {
          // token 无效
          await _apiService.clearTokens();
          _state = const AuthState(isLoading: false);
        }
      } else {
        _state = const AuthState(isLoading: false);
      }
    } catch (e) {
      debugPrint('初始化认证状态失败: $e');
      _state = AuthState(
        isLoading: false,
        error: '初始化失败: $e',
      );
    }

    notifyListeners();
  }

  /// 用户登录
  Future<bool> login(String username, String password) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final result = await _apiService.login(username, password);

      if (result.success && result.user != null) {
        _state = AuthState(
          user: result.user,
          isLoading: false,
          isAuthenticated: true,
        );
        notifyListeners();
        return true;
      } else {
        _state = AuthState(
          isLoading: false,
          error: result.message ?? '登录失败',
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState(
        isLoading: false,
        error: '登录失败: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// 用户注册
  Future<bool> register(String username, String password, {String? inviteCode}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final result = await _apiService.register(username, password, inviteCode: inviteCode);

      if (result.success && result.user != null) {
        _state = AuthState(
          user: result.user,
          isLoading: false,
          isAuthenticated: true,
        );
        notifyListeners();
        return true;
      } else {
        _state = AuthState(
          isLoading: false,
          error: result.message ?? '注册失败',
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState(
        isLoading: false,
        error: '注册失败: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    await _apiService.logout();

    _state = const AuthState();
    notifyListeners();
  }

  /// 获取保存的用户名
  Future<String?> getSavedUsername() async {
    return await _apiService.getSavedUsername();
  }

  /// 获取保存的密码（已解密）
  Future<String?> getSavedPassword() async {
    return await _apiService.getSavedPassword();
  }

  /// 刷新用户信息
  Future<void> refreshUser() async {
    if (!_state.isAuthenticated) return;

    try {
      final user = await _apiService.getCurrentUser();
      if (user != null) {
        _state = _state.copyWith(user: user);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('刷新用户信息失败: $e');
    }
  }

  /// 清除错误
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}
