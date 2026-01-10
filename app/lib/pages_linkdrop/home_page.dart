import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages_linkdrop/home_page_controller.dart';
import 'package:localsend_app/pages_linkdrop/receive_page.dart';
import 'package:localsend_app/pages_linkdrop/send_page.dart';
import 'package:localsend_app/pages_linkdrop/settings_page.dart';
import 'package:localsend_app/pages_linkdrop/widget/sidebar_item.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:refena_flutter/refena_flutter.dart';

enum HomeTab {
  receive(Icons.wifi),
  send(Icons.send),
  settings(Icons.settings);

  const HomeTab(this.icon);

  final IconData icon;

  String get label {
    switch (this) {
      case HomeTab.receive:
        return t.receiveTab.title;
      case HomeTab.send:
        return t.sendTab.title;
      case HomeTab.settings:
        return t.settingsTab.title;
    }
  }
}

/// LinkDrop主页面
///
/// 包含左侧导航栏和右侧内容区域
/// 支持拖拽文件到页面中自动跳转到发送页面
class LinkDropHomePage extends StatefulWidget {
  final HomeTab initialTab;
  final bool appStart;

  const LinkDropHomePage({
    required this.initialTab,
    required this.appStart,
    super.key,
  });

  @override
  State<LinkDropHomePage> createState() => _LinkDropHomePageState();
}

class _LinkDropHomePageState extends State<LinkDropHomePage> with Refena {
  bool _dragAndDropIndicator = false;
  bool _isSidebarExpanded = false;

  @override
  void initState() {
    super.initState();
    ensureRef((ref) async {
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(widget.initialTab));
      await postInit(context, ref, widget.appStart);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch(homePageControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropTarget(
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
        vm.changeTab(HomeTab.send);
      },
      child: Scaffold(
        body: Row(
          children: [
            // 侧边栏（桌面端显示）
            if (MediaQuery.of(context).size.width >= 700) _buildSidebar(context, vm, isDark),

            // 主内容区域
            Expanded(
              child: PageView(
                controller: vm.controller,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  ReceivePage(),
                  SendPage(),
                  SettingsPage(),
                ],
              ),
            ),
          ],
        ),
        // 底部导航栏（移动端显示）
        bottomNavigationBar: MediaQuery.of(context).size.width < 700
            ? NavigationBar(
                selectedIndex: vm.currentTab.index,
                onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.wifi),
                    label: 'Receive',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.send),
                    label: 'Send',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  /// 构建侧边栏
  ///
  /// 包含Logo、切换按钮和导航菜单
  /// 支持展开/收起两种模式
  Widget _buildSidebar(BuildContext context, HomePageVm vm, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isSidebarExpanded ? 250 : 80,
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc950 : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 关键点：侧边栏宽度在动画过程中是逐步变化的。
          // 如果仅用 _isSidebarExpanded 立即显示文字，宽度尚未足够时会触发 RenderFlex overflow。
          // 同时，这里必须保证 Column 的高度约束是有界的（来自父级 AnimatedContainer/Row），否则 Expanded 会布局失败。
          final effectiveExpanded = constraints.maxWidth >= 120;

          return Column(
            children: [
              // Logo区域（可点击切换展开/收起）
              Padding(
                //padding: const EdgeInsets.fromLTRB(12, 24, 12, 8) 导致RenderFlex overflowed by 白底红字错误
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 8),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _isSidebarExpanded ? (isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50) : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: effectiveExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          AnimatedRotation(
                            turns: _isSidebarExpanded ? 0 : 0.5,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : LinkDropColors.zinc900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.send,
                                color: isDark ? LinkDropColors.zinc900 : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          if (effectiveExpanded) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'LinkDrop',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : LinkDropColors.zinc900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 导航菜单
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    SidebarItem(
                      icon: Icons.wifi,
                      label: 'Receive',
                      active: vm.currentTab == HomeTab.receive,
                      onTap: () => vm.changeTab(HomeTab.receive),
                      isDark: isDark,
                      isExpanded: effectiveExpanded,
                    ),
                    SidebarItem(
                      icon: Icons.send,
                      label: 'Send',
                      active: vm.currentTab == HomeTab.send,
                      onTap: () => vm.changeTab(HomeTab.send),
                      isDark: isDark,
                      isExpanded: effectiveExpanded,
                    ),
                    SidebarItem(
                      icon: Icons.settings,
                      label: 'Settings',
                      active: vm.currentTab == HomeTab.settings,
                      onTap: () => vm.changeTab(HomeTab.settings),
                      isDark: isDark,
                      isExpanded: effectiveExpanded,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
