import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/receive_page.dart';
import 'package:localsend_app/pages/send_page.dart';
import 'package:localsend_app/pages/settings_page.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/responsive_builder.dart';
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
  bool _isSidebarExpanded = true;

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
    Translations.of(context); // rebuild on locale change
    final vm = context.watch(homePageControllerProvider);
    final settings = context.watch(settingsProvider);
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
      child: ResponsiveBuilder(
        builder: (sizingInformation) {
          return Scaffold(
            body: Row(
              children: [
                if (!sizingInformation.isMobile)
                  Stack(
                    children: [
                      NavigationRail(
                        selectedIndex: vm.currentTab.index,
                        onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
                        extended: _isSidebarExpanded,
                        backgroundColor: Theme.of(context).cardColorWithElevation,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        indicatorShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        selectedLabelTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        leading: Column(
                          children: [
                            const SizedBox(height: 40),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                onTap: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: AnimatedRotation(
                                          turns: _isSidebarExpanded ? 0 : 0.5,
                                          duration: const Duration(milliseconds: 200),
                                          child: const Icon(
                                            Icons.send,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (_isSidebarExpanded) ...[
                                        const SizedBox(width: 12),
                                        const Text(
                                          'LinkDrop',
                                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                        destinations: HomeTab.values.map((tab) {
                          return NavigationRailDestination(
                            icon: Icon(tab.icon),
                            selectedIcon: Icon(tab.icon, color: Colors.white),
                            label: Text(tab.label),
                          );
                        }).toList(),
                      ),
                      // Bottom items: Theme & Profile
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  onTap: () async {
                                    await ref
                                        .notifier(settingsProvider)
                                        .setTheme(
                                          settings.theme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
                                        );
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: _isSidebarExpanded ? 24 : 0),
                                    child: Row(
                                      mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          settings.theme == ThemeMode.light ? Icons.light_mode : Icons.dark_mode,
                                          size: 24,
                                        ),
                                        if (_isSidebarExpanded) ...[
                                          const SizedBox(width: 12),
                                          Text(
                                            settings.theme == ThemeMode.light ? '日间模式' : '夜间模式',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: PopupMenuButton<String>(
                                  offset: const Offset(40, -120),
                                  tooltip: '',
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      enabled: false,
                                      child: Text(t.settingsTab.general.loginStatus + ': Guest'),
                                    ),
                                    PopupMenuItem(
                                      enabled: false,
                                      child: Text('VIP: ' + t.general.inactive),
                                    ),
                                    PopupMenuItem(
                                      enabled: false,
                                      child: Row(
                                        children: [
                                          Text(t.settingsTab.general.invite + ': 888888'),
                                          const SizedBox(width: 8),
                                          Icon(Icons.copy, size: 16, color: Theme.of(context).colorScheme.primary),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: _isSidebarExpanded ? 24 : 0),
                                    child: Row(
                                      mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          size: 24,
                                        ),
                                        if (_isSidebarExpanded) ...[
                                          const SizedBox(width: 16),
                                          Text(t.settingsTab.general.profile, style: const TextStyle(fontSize: 14)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // makes the top draggable
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 40,
                        child: MoveWindow(),
                      ),
                    ],
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      PageView(
                        controller: vm.controller,
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          SafeArea(child: ReceivePage()),
                          SafeArea(child: SendPage()),
                          SettingsPage(),
                        ],
                      ),
                      if (_dragAndDropIndicator)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.file_download, size: 128),
                              const SizedBox(height: 30),
                              Text(t.sendTab.placeItems, style: Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: sizingInformation.isMobile
                ? NavigationBar(
                    selectedIndex: vm.currentTab.index,
                    onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
                    destinations: HomeTab.values.map((tab) {
                      return NavigationDestination(icon: Icon(tab.icon), label: tab.label);
                    }).toList(),
                  )
                : null,
          );
        },
      ),
    );
  }
}
