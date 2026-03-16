import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:localsend_app/model/user.dart';
import 'package:localsend_app/model/payment_order.dart';

/// API 服务
///
/// 封装所有与后端 API 的通信
class ApiService {
  static String get _baseUrl {
    if (kDebugMode) {
      return 'http://localhost:3000/api';
    } else {
      return 'https://toolapi.dearlinkcn.top/api';
    }
  }

  static const String _accessTokenKey = 'linkdrop_access_token';
  static const String _refreshTokenKey = 'linkdrop_refresh_token';
  static const String _savedUsernameKey = 'linkdrop_saved_username';

  late final Dio _dio;
  late final FlutterSecureStorage _storage;

  // 单例模式
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _storage = const FlutterSecureStorage();
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // 添加日志拦截器（仅在调试模式）
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }

    // 添加拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 自动添加 token
          final token = await getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Token 过期时尝试刷新
          if (error.response?.statusCode == 401) {
            final refreshToken = await getRefreshToken();
            if (refreshToken != null) {
              try {
                final response = await _dio.post(
                  '/auth/refresh',
                  data: {
                    'refresh_token': refreshToken,
                  },
                );
                if (response.data['success'] == true) {
                  final newAccessToken = response.data['data']['accessToken'];
                  final newRefreshToken = response.data['data']['refreshToken'];
                  await setTokens(newAccessToken, newRefreshToken);
                  // 重试原请求
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken}';
                  return handler.resolve(await _dio.fetch(error.requestOptions));
                }
              } catch (e) {
                // 刷新失败，清除 token
                await clearTokens();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// 设置基础 URL
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  // ==================== Token 管理 ====================

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('读取 access token 失败: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('读取 refresh token 失败: $e');
      return null;
    }
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      debugPrint('保存 token 失败: $e');
    }
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('清除 token 失败: $e');
    }
  }

  // ==================== 保存的用户名 ====================

  Future<String?> getSavedUsername() async {
    try {
      return await _storage.read(key: _savedUsernameKey);
    } catch (e) {
      debugPrint('读取保存的用户名失败: $e');
      return null;
    }
  }

  Future<void> setSavedUsername(String username) async {
    try {
      await _storage.write(key: _savedUsernameKey, value: username);
    } catch (e) {
      debugPrint('保存用户名失败: $e');
    }
  }

  Future<void> clearSavedUsername() async {
    try {
      await _storage.delete(key: _savedUsernameKey);
    } catch (e) {
      debugPrint('清除保存的用户名失败: $e');
    }
  }

  // ==================== 用户认证 ====================

  /// 用户登录
  Future<LoginResult> login(String username, String password, {bool rememberMe = false}) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'remember_me': rememberMe,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await setTokens(data['accessToken'], data['refreshToken']);
        // 保存用户名以便下次自动填充
        await setSavedUsername(username);
        return LoginResult(
          success: true,
          user: User.fromJson(data),
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      } else {
        return LoginResult(
          success: false,
          message: response.data['message'] ?? '登录失败',
        );
      }
    } on DioException catch (e) {
      return LoginResult(
        success: false,
        message: e.response?.data['message'] ?? '网络错误，请稍后重试',
      );
    } catch (e) {
      return LoginResult(
        success: false,
        message: '登录失败: $e',
      );
    }
  }

  /// 用户注册
  Future<LoginResult> register(String username, String password, {String? inviteCode}) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'confirmPassword': password,
          'securityQuestion': '默认问题',
          'securityAnswer': 'default',
          if (inviteCode != null) 'invite_code': inviteCode,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await setTokens(data['accessToken'], data['refreshToken']);
        return LoginResult(
          success: true,
          user: User.fromJson(data),
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      } else {
        return LoginResult(
          success: false,
          message: response.data['message'] ?? '注册失败',
        );
      }
    } on DioException catch (e) {
      return LoginResult(
        success: false,
        message: e.response?.data['message'] ?? '网络错误，请稍后重试',
      );
    } catch (e) {
      return LoginResult(
        success: false,
        message: '注册失败: $e',
      );
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      debugPrint('退出登录请求失败: $e');
    } finally {
      await clearTokens();
    }
  }

  /// 获取当前用户信息
  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.data['success'] == true) {
        return User.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      return null;
    }
  }

  // ==================== 充值商品 ====================

  /// 获取充值商品列表
  Future<List<RechargeItem>> getRechargeItems() async {
    try {
      final response = await _dio.get('/recharge/items');
      if (response.data['success'] == true) {
        final items = response.data['data'] as List;
        return items.map((item) => RechargeItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('获取充值商品失败: $e');
      return [];
    }
  }

  // ==================== 支付订单 ====================

  /// 创建充值订单
  Future<PaymentOrder?> createRechargeOrder(int itemId) async {
    try {
      final response = await _dio.post(
        '/recharge/orders',
        data: {
          'item_id': itemId,
        },
      );

      if (response.data['success'] == true) {
        return PaymentOrder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('创建订单失败: $e');
      return null;
    }
  }

  /// 创建支付（获取二维码）
  Future<PaymentOrder?> createPayment(int orderId) async {
    try {
      final response = await _dio.post(
        '/payment/alipay/facetoface/create',
        data: {
          'order_id': orderId,
        },
      );

      if (response.data['success'] == true) {
        return PaymentOrder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('创建支付失败: $e');
      return null;
    }
  }

  /// 查询支付状态
  Future<PaymentOrder?> queryPaymentStatus(String orderNo) async {
    try {
      final response = await _dio.get('/payment/queryOrderStatus/$orderNo');

      if (response.data['success'] == true) {
        return PaymentOrder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('查询支付状态失败: $e');
      return null;
    }
  }

  /// 获取用户订单列表
  Future<List<PaymentOrder>> getUserOrders() async {
    try {
      final response = await _dio.get('/auth/orders');
      if (response.data['success'] == true) {
        final orders = response.data['data'] as List;
        return orders.map((order) => PaymentOrder.fromJson(order)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('获取订单列表失败: $e');
      return [];
    }
  }

  /// 重新激活过期订单
  Future<PaymentOrder?> reactivateOrder(int orderId) async {
    try {
      final response = await _dio.post('/payment/orders/reactivate/$orderId');

      if (response.data['success'] == true) {
        return PaymentOrder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('重新激活订单失败: $e');
      return null;
    }
  }
}

/// 登录结果
class LoginResult {
  final bool success;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? message;

  const LoginResult({
    required this.success,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.message,
  });
}

/// 充值商品
class RechargeItem {
  final int id;
  final String name;
  final double price;
  final int? days;
  final int downloadCount;
  final int dailyLimit;
  final int type; // 0: 会员套餐, 1: 下载包

  const RechargeItem({
    required this.id,
    required this.name,
    required this.price,
    this.days,
    this.downloadCount = 0,
    this.dailyLimit = 30,
    this.type = 0,
  });

  factory RechargeItem.fromJson(Map<String, dynamic> json) {
    return RechargeItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      days: json['days'],
      downloadCount: json['download_count'] ?? 0,
      dailyLimit: json['daily_limit'] ?? 30,
      type: json['type'] ?? 0,
    );
  }

  /// 是否为会员套餐
  bool get isMembership => type == 0;

  /// 是否为永久会员
  bool get isPermanent => days == null;
}
