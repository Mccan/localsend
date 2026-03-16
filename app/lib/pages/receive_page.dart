import 'dart:async';

import 'package:common/model/session_status.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/state/settings_state.dart';
import 'package:localsend_app/pages/receive_history_page.dart';
import 'package:localsend_app/pages/tabs/receive_tab_vm.dart';
import 'package:localsend_app/pages/widget/pulse_ripple.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/ip_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// 设备信息与热点提示整合卡片
class _DeviceInfoCard extends StatelessWidget {
  final bool isDark;
  final String alias;
  final bool isAliasModified;
  final String? ip;
  final String? port;
  final VoidCallback onTapAlias;

  const _DeviceInfoCard({
    required this.isDark,
    required this.alias,
    required this.isAliasModified,
    this.ip,
    this.port,
    required this.onTapAlias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [const Color(0xFF2D2418), const Color(0xFF1A1510)] : [const Color(0xFFFDF8F3), const Color(0xFFF5EDE4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3D3220) : const Color(0xFFE8DDD0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : const Color(0x1AD4A574),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：设备名称 + 热点标签
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LinkDropColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.wifi_tethering_rounded,
                  color: LinkDropColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onTapAlias,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDisplayName(alias, isAliasModified, ip),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : LinkDropColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ip != null ? '$ip:${port ?? '-'}' : '等待连接...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF999999) : const Color(0xFF888888),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: LinkDropColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 第二行：三步流程
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1510) : const Color(0xFFFDFBF8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF2D2418) : const Color(0xFFF0E8E0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStepItem('1', '开热点', isDark),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: LinkDropColors.primary.withOpacity(0.5),
                ),
                Expanded(
                  child: _buildStepItem('2', '连热点', isDark),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: LinkDropColors.primary.withOpacity(0.5),
                ),
                Expanded(
                  child: _buildStepItem('3', '传文件', isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayName(String alias, bool isAliasModified, String? ip) {
    if (isAliasModified || ip == null) {
      return alias;
    }
    return '${ip.visualId}（我）';
  }

  Widget _buildStepItem(String number, String label, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: LinkDropColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: LinkDropColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}

/// 接收页面
///
/// 显示接收文件的状态和本地IP地址
/// 支持快速保存功能和历史记录查看
class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _dotCount = 1;
  Timer? _timer;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startDotAnimation();
  }

  void _startDotAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _dotCount = (_dotCount % 3) + 1;
      });
    });
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  String _getStatusText(SessionStatus? status) {
    if (status == null) {
      return t.receiveTab.readyToReceive;
    }

    switch (status) {
      case SessionStatus.sending:
        return t.receiveTab.receiving;
      case SessionStatus.finished:
      case SessionStatus.finishedWithErrors:
        return t.receiveTab.received;
      default:
        return t.receiveTab.readyToReceive;
    }
  }

  /// 构建带动画的点
  Widget _buildAnimatedDot(int index, bool isDark) {
    // 计算当前点的动画进度
    // 三个点交替亮起，形成追逐效果
    final animationProgress = (_dotCount + index) % 3;
    final isActive = animationProgress == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: isActive ? LinkDropColors.primary : (isDark ? Colors.white : LinkDropColors.textPrimary).withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch(receiveTabVmProvider);
    final settings = context.watch(settingsProvider);
    final settingsService = context.notifier(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionStatus = vm.serverState?.session?.status;

    if (sessionStatus == SessionStatus.finished || sessionStatus == SessionStatus.finishedWithErrors) {
      _scheduleReset();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 顶部标题栏
          Padding(
            padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 16, 32, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            t.receiveTab.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : LinkDropColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          // 历史记录按钮
                          IconButton(
                            onPressed: () {
                              // ignore: discarded_futures
                              context.push(() => const ReceiveHistoryPage());
                            },
                            icon: const Icon(Icons.history),
                            tooltip: 'History',
                            color: LinkDropColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.receiveTab.subtitle,
                        style: TextStyle(
                          color: LinkDropColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 设备信息与热点提示整合卡片
          _DeviceInfoCard(
            isDark: isDark,
            alias: settings.alias,
            isAliasModified: settings.isAliasModified,
            ip: vm.localIps.firstOrNull,
            port: vm.serverState?.port.toString(),
            onTapAlias: () => _showAliasDialog(context, settings, settingsService),
          ),

          // 主内容区域
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 脉冲动画图标
                  PulseRipple(
                    color: LinkDropColors.primary,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: isDark ? LinkDropColors.zinc900 : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.download_rounded,
                        size: 64,
                        color: LinkDropColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.receiveTab.readyToReceive,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : LinkDropColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 交替追逐动画的三个点
                      SizedBox(
                        width: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildAnimatedDot(0, isDark),
                            _buildAnimatedDot(1, isDark),
                            _buildAnimatedDot(2, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 自动保存开关
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? LinkDropColors.zinc900 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.general.quickSave,
                          style: TextStyle(
                            color: isDark ? Colors.white : LinkDropColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: vm.quickSaveSettings,
                          onChanged: (value) => vm.onSetQuickSave(context, value),
                          activeThumbColor: LinkDropColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAliasDialog(BuildContext context, SettingsState settings, SettingsService settingsService) {
    final controller = TextEditingController(text: settings.alias);

    // ignore: discarded_futures
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.receiveTab.infoBox.alias),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: t.receiveTab.infoBox.alias,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // ignore: discarded_futures
              Navigator.of(context).pop();
            },
            child: Text(t.general.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // ignore: discarded_futures
                settingsService.setAlias(controller.text);
              }
              // ignore: discarded_futures
              Navigator.of(context).pop();
            },
            child: Text(t.general.save),
          ),
        ],
      ),
    );
  }
}
