import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/pages/language_page.dart';
import 'package:localsend_app/pages/tabs/settings_tab_controller.dart';
import 'package:localsend_app/pages_linkdrop/widget/settings_group.dart';
import 'package:localsend_app/pages_linkdrop/widget/settings_item.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/native/pick_directory_path.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:refena_flutter/refena_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final vm = context.watch(settingsTabControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.settingsTab.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : LinkDropColors.zinc900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage your preferences',
                      style: TextStyle(
                        color: LinkDropColors.zinc500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Advanced Toggle
                Row(
                  children: [
                    Text(
                      'Advanced',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? LinkDropColors.zinc400 : LinkDropColors.zinc500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: vm.advanced,
                      onChanged: (b) => vm.onTapAdvanced(b),
                      activeColor: LinkDropColors.teal500,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children: [
                // General
                SettingsGroup(
                  title: t.settingsTab.general.title,
                  isDark: isDark,
                  children: [
                    SettingsItem(
                      icon: Icons.language,
                      title: t.settingsTab.general.language,
                      value: vm.settings.locale?.humanName ?? t.settingsTab.general.languageOptions.system,
                      isDark: isDark,
                      onTap: () => vm.onTapLanguage(context),
                    ),
                    SettingsItem(
                      icon: Icons.brightness_6,
                      title: t.settingsTab.general.brightness,
                      isDark: isDark,
                      trailing: DropdownButton<ThemeMode>(
                        value: vm.settings.theme,
                        dropdownColor: isDark ? LinkDropColors.zinc800 : Colors.white,
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, color: LinkDropColors.zinc500),
                        items: vm.themeModes.map((theme) {
                          return DropdownMenuItem(
                            value: theme,
                            child: Text(
                              theme.humanName,
                              style: TextStyle(
                                color: isDark ? Colors.white : LinkDropColors.zinc900,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (theme) => vm.onChangeTheme(context, theme!),
                      ),
                    ),
                    SettingsItem(
                      icon: Icons.palette,
                      title: t.settingsTab.general.color,
                      isDark: isDark,
                      trailing: DropdownButton<ColorMode>(
                        value: vm.settings.colorMode,
                        dropdownColor: isDark ? LinkDropColors.zinc800 : Colors.white,
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, color: LinkDropColors.zinc500),
                        items: vm.colorModes.map((mode) {
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(
                              mode.humanName,
                              style: TextStyle(
                                color: isDark ? Colors.white : LinkDropColors.zinc900,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (mode) {
                          if (mode != null) {
                            vm.onChangeColorMode(mode);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // Receive
                SettingsGroup(
                  title: t.settingsTab.receive.title,
                  isDark: isDark,
                  children: [
                    SettingsItem(
                      icon: Icons.save_alt,
                      title: t.settingsTab.receive.quickSave,
                      isDark: isDark,
                      trailing: Switch(
                        value: vm.settings.quickSave,
                        activeColor: LinkDropColors.teal500,
                        onChanged: (b) => ref.notifier(settingsProvider).setQuickSave(b),
                      ),
                    ),
                    if (checkPlatformWithFileSystem())
                      SettingsItem(
                        icon: Icons.folder_open,
                        title: t.settingsTab.receive.destination,
                        value: vm.settings.destination ?? t.settingsTab.receive.downloads,
                        isDark: isDark,
                        onTap: () async {
                          final directory = await pickDirectoryPath();
                          if (directory != null) {
                            await ref.notifier(settingsProvider).setDestination(directory);
                          }
                        },
                      ),
                    SettingsItem(
                      icon: Icons.check_circle_outline,
                      title: t.settingsTab.receive.autoFinish,
                      isDark: isDark,
                      trailing: Switch(
                        value: vm.settings.autoFinish,
                        activeColor: LinkDropColors.teal500,
                        onChanged: (b) => ref.notifier(settingsProvider).setAutoFinish(b),
                      ),
                    ),
                    SettingsItem(
                      icon: Icons.history,
                      title: t.settingsTab.receive.saveToHistory,
                      isDark: isDark,
                      trailing: Switch(
                        value: vm.settings.saveToHistory,
                        activeColor: LinkDropColors.teal500,
                        onChanged: (b) => ref.notifier(settingsProvider).setSaveToHistory(b),
                      ),
                    ),
                  ],
                ),

                // Network
                SettingsGroup(
                  title: t.settingsTab.network.title,
                  isDark: isDark,
                  children: [
                    SettingsItem(
                      icon: Icons.dns,
                      title: 'Alias',
                      value: vm.settings.alias,
                      isDark: isDark,
                      onTap: () {
                        // TODO: Show edit dialog
                      },
                    ),
                    SettingsItem(
                      icon: Icons.numbers,
                      title: 'Port',
                      value: vm.settings.port.toString(),
                      isDark: isDark,
                    ),
                    SettingsItem(
                      icon: Icons.lock_outline,
                      title: 'Encryption',
                      isDark: isDark,
                      trailing: Switch(
                        value: vm.settings.https,
                        activeColor: LinkDropColors.teal500,
                        onChanged: (b) => ref.notifier(settingsProvider).setHttps(b),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on ThemeMode {
  String get humanName {
    switch (this) {
      case ThemeMode.system:
        return t.settingsTab.general.brightnessOptions.system;
      case ThemeMode.light:
        return t.settingsTab.general.brightnessOptions.light;
      case ThemeMode.dark:
        return t.settingsTab.general.brightnessOptions.dark;
    }
  }
}

extension on ColorMode {
  String get humanName {
    return switch (this) {
      ColorMode.system => t.settingsTab.general.colorOptions.system,
      ColorMode.localsend => t.appName,
      ColorMode.oled => t.settingsTab.general.colorOptions.oled,
      ColorMode.yaru => 'Yaru',
    };
  }
}
