import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/pages/selected_files_page.dart';
import 'package:localsend_app/pages/tabs/send_tab_vm.dart';
import 'package:localsend_app/pages/widget/device_node.dart';
import 'package:localsend_app/pages/widget/pulse_ripple.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/widget/dialogs/send_mode_help_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// 发送页面
///
/// 支持文件选择、设备扫描和文件发送
/// 提供多种发送模式：单个接收者、多个接收者、通过链接分享
class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> with Refena {
  bool _dragAndDropIndicator = false;
  bool _isScanning = false;

  Future<void> _handleScan(BuildContext context) async {
    setState(() {
      _isScanning = true;
    });

    context.redux(nearbyDevicesProvider).dispatch(ClearFoundDevicesAction());

    try {
      await context.global.dispatchAsync(StartSmartScan(forceLegacy: true));
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch(sendTabVmProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 顶部标题栏
          Padding(
            padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 16, 32, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.sendTab.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : LinkDropColors.zinc900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.sendTab.subtitle,
                      style: TextStyle(
                        color: LinkDropColors.zinc500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
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
                    children: [
                      Expanded(
                        child: _ControlButton(
                          icon: Icons.refresh_rounded,
                          label: t.sendTab.scan,
                          onTap: () => _handleScan(context),
                          isDark: isDark,
                          isRotating: _isScanning,
                        ),
                      ),
                      Expanded(
                        child: _ControlButton(
                          icon: Icons.keyboard_alt_rounded,
                          label: t.sendTab.manualSending,
                          onTap: () => vm.onTapAddress(context),
                          isDark: isDark,
                        ),
                      ),
                      Expanded(
                        child: _SendModeButton(
                          label: vm.sendMode.humanName,
                          isDark: isDark,
                          onSelect: (mode) => vm.onTapSendMode(context, mode),
                        ),
                      ),
                    ],
                  ),
                ),

                // 设备列表
                Expanded(
                  child: vm.nearbyDevices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PulseRipple(
                                color: isDark ? LinkDropColors.teal500 : LinkDropColors.teal600,
                                shouldRotate: true,
                                child: Icon(
                                  Icons.radar_rounded,
                                  size: 48,
                                  color: isDark ? LinkDropColors.teal500 : LinkDropColors.teal600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                t.sendTab.scanning,
                                style: TextStyle(
                                  color: LinkDropColors.zinc500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vm.nearbyDevices.length,
                          itemBuilder: (context, index) {
                            final device = vm.nearbyDevices.elementAt(index);
                            final isFavorite = vm.favoriteDevices.any((fav) => fav.fingerprint == device.fingerprint);
                            return DeviceNode(
                              device: device,
                              isDark: isDark,
                              isFavorite: isFavorite,
                              onTap: () => vm.onTapDevice(context, device),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // 顶部区域：文件选择区
          Expanded(
            flex: 4,
            child: DropTarget(
              onDragEntered: (_) => setState(() => _dragAndDropIndicator = true),
              onDragExited: (_) => setState(() => _dragAndDropIndicator = false),
              onDragDone: (event) async {
                if (event.files.length == 1 && Directory(event.files.first.path).existsSync()) {
                  await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(event.files.first.path));
                } else {
                  await ref
                      .redux(selectedSendingFilesProvider)
                      .dispatchAsync(
                        AddFilesAction(
                          files: event.files,
                          converter: CrossFileConverters.convertXFile,
                        ),
                      );
                }
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: isDark ? LinkDropColors.zinc900.withValues(alpha: 0.5) : LinkDropColors.zinc50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _dragAndDropIndicator
                        ? LinkDropColors.teal500
                        : isDark
                        ? LinkDropColors.zinc800
                        : LinkDropColors.zinc200,
                    style: BorderStyle.solid,
                    width: _dragAndDropIndicator ? 3 : 2,
                  ),
                ),
                child: vm.selectedFiles.isEmpty ? _buildSelectionOptions(context, vm, isDark) : _buildSelectedFiles(context, vm, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建选择选项区域
  ///
  /// 显示多种文件选择方式：文件、文件夹、媒体、文本、剪贴板
  Widget _buildSelectionOptions(BuildContext context, SendTabVm vm, bool isDark) {
    final options = FilePickerOption.getOptionsForPlatform();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            t.sendTab.selectFiles,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : LinkDropColors.zinc900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, index) {
                final option = options[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _SelectionOptionButton(
                    icon: option.icon,
                    label: option.label,
                    isDark: isDark,
                    onTap: () => _pickFiles(context, option),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建已选文件区域
  ///
  /// 显示已选文件的预览和操作按钮
  Widget _buildSelectedFiles(BuildContext context, SendTabVm vm, bool isDark) {
    final totalSize = vm.selectedFiles.fold<int>(0, (prev, curr) => prev + curr.size);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selected files',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
              ),
              // 清除按钮
              InkWell(
                onTap: () => context.ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction()),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: LinkDropColors.zinc500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 文件统计信息
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_rounded,
                    size: 14,
                    color: LinkDropColors.teal500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${vm.selectedFiles.length} files',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : LinkDropColors.zinc700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 14,
                    color: LinkDropColors.teal500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    totalSize.asReadableFileSize,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : LinkDropColors.zinc700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 文件缩略图列表（横向滚动）
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: vm.selectedFiles.length,
              itemBuilder: (context, index) {
                final file = vm.selectedFiles[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _FileThumbnailCard(
                    file: file,
                    isDark: isDark,
                    onTap: () => _removeFile(context, index),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_rounded,
                  label: t.sendTab.addMore,
                  isDark: isDark,
                  onTap: () => _pickFiles(context, FilePickerOption.file),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_rounded,
                  label: t.sendTab.editList,
                  isDark: isDark,
                  onTap: () => _showFileList(context, vm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 移除文件
  ///
  /// 从选中列表中移除指定索引的文件
  void _removeFile(BuildContext context, int index) {
    context.ref.redux(selectedSendingFilesProvider).dispatch(RemoveSelectedFileAction(index));
  }

  /// 显示完整文件列表
  ///
  /// 跳转到文件列表编辑页面
  void _showFileList(BuildContext context, SendTabVm vm) {
    // ignore: discarded_futures
    context.push(() => const SelectedFilesPage());
  }

  /// 选择文件
  ///
  /// 根据指定的选项选择文件
  void _pickFiles(BuildContext context, FilePickerOption option) {
    // ignore: discarded_futures
    context.ref.global.dispatchAsync(
      PickFileAction(
        option: option,
        context: context,
      ),
    );
  }
}

/// 选择选项按钮组件
///
/// 用于显示文件选择方式按钮
class _SelectionOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _SelectionOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? LinkDropColors.zinc800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? LinkDropColors.zinc900 : LinkDropColors.zinc50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: LinkDropColors.teal500),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : LinkDropColors.zinc900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 控制按钮组件
///
/// 用于显示操作按钮（扫描、手动输入、收藏、发送模式）
class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isRotating;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isRotating = false,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(_ControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRotating && !oldWidget.isRotating) {
      _controller.repeat();
    } else if (!widget.isRotating && oldWidget.isRotating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isDark ? LinkDropColors.zinc800 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                ),
              ),
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.141592653589793,
                    child: Icon(widget.icon, size: 20, color: LinkDropColors.teal500),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
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
        return t.sendTab.sendModes.single;
      case SendMode.multiple:
        return t.sendTab.sendModes.multiple;
      case SendMode.link:
        return t.sendTab.sendModes.link;
    }
  }
}

/// 文件缩略图卡片组件
///
/// 显示单个文件的缩略图和基本信息
class _FileThumbnailCard extends StatelessWidget {
  final CrossFile file;
  final bool isDark;
  final VoidCallback onTap;

  const _FileThumbnailCard({
    required this.file,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 70,
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
        ),
        child: Column(
          children: [
            // 缩略图区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SmartFileThumbnail.fromCrossFile(file),
              ),
            ),
            // 文件名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white70 : LinkDropColors.zinc700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 操作按钮组件
///
/// 用于显示添加更多、编辑列表等操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: LinkDropColors.teal500,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : LinkDropColors.zinc900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 发送模式按钮组件
///
/// 用于选择发送模式（单个接收者、多个接收者、通过链接分享）
class _SendModeButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final void Function(SendMode mode) onSelect;

  const _SendModeButton({
    required this.label,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: t.sendTab.sendMode,
      offset: const Offset(0, 40),
      onSelected: (mode) async {
        switch (mode) {
          case 0:
            onSelect(SendMode.single);
            break;
          case 1:
            onSelect(SendMode.multiple);
            break;
          case 2:
            onSelect(SendMode.link);
            break;
          case -1:
            await showDialog(context: context, builder: (_) => const SendModeHelpDialog());
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref) {
                  final sendMode = ref.watch(settingsProvider.select((s) => s.sendMode));
                  return Visibility(
                    visible: sendMode == SendMode.single,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: const Icon(Icons.check_circle),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(t.sendTab.sendModes.single),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref) {
                  final sendMode = ref.watch(settingsProvider.select((s) => s.sendMode));
                  return Visibility(
                    visible: sendMode == SendMode.multiple,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: const Icon(Icons.check_circle),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(t.sendTab.sendModes.multiple),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Icon(Icons.check_circle),
              ),
              const SizedBox(width: 10),
              Text(t.sendTab.sendModes.link),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: -1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(Icons.help),
              ),
              const SizedBox(width: 10),
              Text(t.sendTab.sendModeHelp),
            ],
          ),
        ),
      ],
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
              child: const Icon(Icons.tune_rounded, size: 20, color: LinkDropColors.teal500),
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
