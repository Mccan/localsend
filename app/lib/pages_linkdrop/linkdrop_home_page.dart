import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages_linkdrop/receive_page.dart';
import 'package:localsend_app/pages_linkdrop/send_page.dart';
import 'package:localsend_app/pages_linkdrop/settings_page.dart';
import 'package:localsend_app/pages_linkdrop/widget/sidebar_item.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:refena_flutter/refena_flutter.dart';

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
          await ref.redux(selectedSendingFilesProvider).dispatchAsync(
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
            // Sidebar (Desktop)
            if (MediaQuery.of(context).size.width >= 700)
              _buildSidebar(context, vm, isDark),

            // Main Content
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
        // Bottom Navigation (Mobile)
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

  Widget _buildSidebar(BuildContext context, HomePageVm vm, bool isDark) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc950 : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
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
                const SizedBox(width: 12),
                Text(
                  'LinkDrop',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
              ],
            ),
          ),

          // Navigation
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
                ),
                SidebarItem(
                  icon: Icons.send,
                  label: 'Send',
                  active: vm.currentTab == HomeTab.send,
                  onTap: () => vm.changeTab(HomeTab.send),
                  isDark: isDark,
                ),
                SidebarItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  active: vm.currentTab == HomeTab.settings,
                  onTap: () => vm.changeTab(HomeTab.settings),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

