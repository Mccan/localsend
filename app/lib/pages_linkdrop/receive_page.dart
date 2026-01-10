import 'dart:async';

import 'package:common/model/session_status.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/state/settings_state.dart';
import 'package:localsend_app/pages/receive_history_page.dart';
import 'package:localsend_app/pages/tabs/receive_tab_vm.dart';
import 'package:localsend_app/pages_linkdrop/widget/pulse_ripple.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

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
      return '${t.receiveTab.readyToReceive}${'.' * _dotCount}';
    }

    switch (status) {
      case SessionStatus.sending:
        return '${t.receiveTab.receiving}${'.' * _dotCount}';
      case SessionStatus.finished:
      case SessionStatus.finishedWithErrors:
        return t.receiveTab.received;
      default:
        return '${t.receiveTab.readyToReceive}${'.' * _dotCount}';
    }
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
                              color: isDark ? Colors.white : LinkDropColors.zinc900,
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
                            color: LinkDropColors.zinc500,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.receiveTab.subtitle,
                        style: TextStyle(
                          color: LinkDropColors.zinc500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 高级信息直接显示
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoItem(
                            label: t.receiveTab.infoBox.alias,
                            value: settings.alias,
                            onTap: () => _showAliasDialog(context, settings, settingsService),
                            isDark: isDark,
                          ),
                          if (vm.localIps.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _InfoItem(
                                label: t.receiveTab.infoBox.ip,
                                value: vm.localIps.first,
                                isDark: isDark,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _InfoItem(
                              label: t.receiveTab.infoBox.port,
                              value: vm.serverState?.port.toString() ?? '-',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 主内容区域
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 脉冲动画图标
                  PulseRipple(
                    color: LinkDropColors.teal500,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: isDark ? LinkDropColors.zinc900 : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        size: 64,
                        color: LinkDropColors.teal500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    '${t.receiveTab.readyToReceive}${'.' * _dotCount}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 别名显示
                  InkWell(
                    onTap: () {
                      _showAliasDialog(context, settings, settingsService);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi, size: 16, color: LinkDropColors.zinc500),
                          const SizedBox(width: 8),
                          Text(
                            settings.alias,
                            style: const TextStyle(
                              fontSize: 16,
                              color: LinkDropColors.zinc500,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.edit, size: 14, color: LinkDropColors.zinc500),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 自动保存开关
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? LinkDropColors.zinc900 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.general.quickSave,
                          style: TextStyle(
                            color: isDark ? Colors.white : LinkDropColors.zinc900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: vm.quickSaveSettings,
                          onChanged: (value) => vm.onSetQuickSave(context, value),
                          activeThumbColor: LinkDropColors.teal500,
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isDark;

  const _InfoItem({
    required this.label,
    required this.value,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: LinkDropColors.zinc500,
              fontSize: 12,
            ),
          ),
          SelectableText(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : LinkDropColors.zinc900,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.edit,
              size: 12,
              color: LinkDropColors.zinc500,
            ),
          ],
        ],
      ),
    );
  }
}
