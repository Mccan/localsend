import 'package:common/model/device.dart';
import 'package:common/model/file_type.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/pages/tabs/send_tab_vm.dart';
import 'package:localsend_app/pages_linkdrop/widget/device_node.dart';
import 'package:localsend_app/pages_linkdrop/widget/pulse_ripple.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/send_mode_help_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// 发送页面
///
/// 支持文件选择、设备扫描和文件发送
/// 提供多种发送模式：单个接收者、多个接收者、通过链接分享
class SendPage extends StatelessWidget {
  const SendPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch(sendTabVmProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 统计文件类型数量
    int imageCount = 0;
    int videoCount = 0;
    int docCount = 0;
    int otherCount = 0;

    for (final file in vm.selectedFiles) {
      switch (file.fileType) {
        case FileType.image:
          imageCount++;
          break;
        case FileType.video:
          videoCount++;
          break;
        case FileType.pdf:
        case FileType.text:
          docCount++;
          break;
        default:
          otherCount++;
          break;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 顶部区域：文件选择区
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: isDark ? LinkDropColors.zinc900.withOpacity(0.5) : LinkDropColors.zinc50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => _pickFiles(context),
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 脉冲动画
                    PulseRipple(
                      color: LinkDropColors.teal500,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDark ? LinkDropColors.zinc900 : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
                          ),
                        ),
                        child: Icon(
                          vm.selectedFiles.isEmpty ? Icons.add_rounded : Icons.check_rounded,
                          size: 48,
                          color: LinkDropColors.teal500,
                        ),
                      ),
                    ),

                    // 文本信息
                    Positioned(
                      bottom: 40,
                      child: Column(
                        children: [
                          Text(
                            vm.selectedFiles.isEmpty ? 'Tap to select files' : '${vm.selectedFiles.length} files selected',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : LinkDropColors.zinc900,
                            ),
                          ),
                          if (vm.selectedFiles.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Tap to add more',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: LinkDropColors.zinc500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 底部区域：设备发现
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // 控制栏
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlButton(
                        icon: Icons.refresh_rounded,
                        label: 'Scan',
                        onTap: () => context.global.dispatchAsync(StartSmartScan(forceLegacy: true)),
                        isDark: isDark,
                      ),
                      _ControlButton(
                        icon: Icons.keyboard_alt_rounded,
                        label: 'Manual',
                        onTap: () => vm.onTapAddress(context),
                        isDark: isDark,
                      ),
                      _ControlButton(
                        icon: Icons.favorite_rounded,
                        label: 'Favorites',
                        onTap: () => vm.onTapFavorite(context),
                        isDark: isDark,
                      ),
                      _ControlButton(
                        icon: Icons.tune_rounded,
                        label: vm.sendMode.humanName,
                        onTap: () => context.push(() => const SendModeHelpDialog()),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // 设备列表
                Expanded(
                  child: vm.nearbyDevices.isEmpty
                      ? Center(
                          child: Text(
                            'Scanning for nearby devices...',
                            style: TextStyle(
                              color: LinkDropColors.zinc500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vm.nearbyDevices.length,
                          itemBuilder: (context, index) {
                            final device = vm.nearbyDevices.elementAt(index);
                            return DeviceNode(
                              device: device,
                              isDark: isDark,
                              onTap: () => vm.onTapDevice(context, device),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 选择文件
  ///
  /// 根据平台自动选择合适的文件选择器
  /// 移动端使用媒体选择器，PC端使用通用文件选择器
  void _pickFiles(BuildContext context) {
    final option = checkPlatform([TargetPlatform.android, TargetPlatform.iOS]) ? FilePickerOption.media : FilePickerOption.file;
    context.ref.global.dispatchAsync(
      PickFileAction(
        option: option,
        context: context,
      ),
    );
  }
}

/// 控制按钮组件
///
/// 用于显示操作按钮（扫描、手动输入、收藏、发送模式）
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? LinkDropColors.zinc800 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                ),
              ),
              child: Icon(icon, size: 20, color: LinkDropColors.teal500),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: LinkDropColors.zinc500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on SendMode {
  String get humanName {
    switch (this) {
      case SendMode.single:
        return 'Single Recipient';
      case SendMode.multiple:
        return 'Multiple Recipients';
      case SendMode.link:
        return 'Share via Link';
    }
  }
}
