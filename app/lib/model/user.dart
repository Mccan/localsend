/// 用户模型
///
/// 表示应用中的用户数据
class User {
  final int id;
  final String username;
  final String? email;
  final String? phone;
  final bool isVip;
  final DateTime? vipExpiresAt;
  final int downloadCount;
  final int dailyDownloadCount;
  final DateTime? lastDailyReset;
  final int vipDailyLimit;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    this.isVip = false,
    this.vipExpiresAt,
    this.downloadCount = 0,
    this.dailyDownloadCount = 0,
    this.lastDailyReset,
    this.vipDailyLimit = 30,
    this.inviteCode,
    required this.createdAt,
    this.lastLogin,
  });

  /// 从 JSON 创建用户
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['userId'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'],
      phone: json['phone'],
      isVip: json['isVip'] ?? json['is_vip'] ?? false,
      vipExpiresAt: json['vipExpiresAt'] != null
          ? DateTime.tryParse(json['vipExpiresAt'])
          : json['vip_expires_at'] != null
              ? DateTime.tryParse(json['vip_expires_at'])
              : null,
      downloadCount: json['downloadCount'] ?? json['download_count'] ?? 0,
      dailyDownloadCount: json['dailyDownloadCount'] ?? json['daily_download_count'] ?? 0,
      lastDailyReset: json['lastDailyReset'] != null
          ? DateTime.tryParse(json['lastDailyReset'])
          : json['last_daily_reset'] != null
              ? DateTime.tryParse(json['last_daily_reset'])
              : null,
      vipDailyLimit: json['vipDailyLimit'] ?? json['vip_daily_limit'] ?? 30,
      inviteCode: json['inviteCode'] ?? json['invite_code'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'])
          : json['last_login_at'] != null
              ? DateTime.tryParse(json['last_login_at'])
              : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'isVip': isVip,
      'vipExpiresAt': vipExpiresAt?.toIso8601String(),
      'downloadCount': downloadCount,
      'dailyDownloadCount': dailyDownloadCount,
      'lastDailyReset': lastDailyReset?.toIso8601String(),
      'vipDailyLimit': vipDailyLimit,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  /// 复制并修改
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? phone,
    bool? isVip,
    DateTime? vipExpiresAt,
    int? downloadCount,
    int? dailyDownloadCount,
    DateTime? lastDailyReset,
    int? vipDailyLimit,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isVip: isVip ?? this.isVip,
      vipExpiresAt: vipExpiresAt ?? this.vipExpiresAt,
      downloadCount: downloadCount ?? this.downloadCount,
      dailyDownloadCount: dailyDownloadCount ?? this.dailyDownloadCount,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
      vipDailyLimit: vipDailyLimit ?? this.vipDailyLimit,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  /// VIP 是否有效
  bool get isVipActive {
    if (!isVip) return false;
    if (vipExpiresAt == null) return true; // 永久会员
    return vipExpiresAt!.isAfter(DateTime.now());
  }

  /// VIP 剩余天数
  int get vipRemainingDays {
    if (!isVip || vipExpiresAt == null) return 0;
    final remaining = vipExpiresAt!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}