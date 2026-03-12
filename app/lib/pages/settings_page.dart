import 'package:common/model/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/pages/language_page.dart';
import 'package:localsend_app/pages/login_page.dart';
import 'package:localsend_app/pages/payment_page.dart';
import 'package:localsend_app/pages/tabs/settings_tab_controller.dart';
import 'package:localsend_app/pages/widget/settings_group.dart';
import 'package:localsend_app/pages/widget/settings_item.dart';
import 'package:localsend_app/provider/auth_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/util/native/context_menu_helper.dart';
import 'package:localsend_app/util/native/pick_directory_path.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:provider/provider.dart' as provider;
import 'package:refena_flutter/refena_flutter.dart';

/// 设置页面
///
/// 提供应用程序的各种设置选项
/// 包括常规设置、接收设置和网络设置
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaultSettings();
    });
  }

  Future<void> _initializeDefaultSettings() async {
    final ref = context.ref;
    final settings = ref.read(settingsProvider);

    final futures = <Future>[];

    futures.add(ref.notifier(settingsProvider).setEnableAnimations(true));
    futures.add(ref.notifier(settingsProvider).setQuickSave(true));
    futures.add(ref.notifier(settingsProvider).setAutoFinish(true));
    futures.add(ref.notifier(settingsProvider).setSaveToHistory(true));
    futures.add(ref.notifier(settingsProvider).setHttps(true));
    futures.add(ref.notifier(settingsProvider).setShareViaLinkAutoAccept(true));

    if (checkPlatformIsDesktop()) {
      futures.add(ref.notifier(settingsProvider).setSaveWindowPlacement(true));
      futures.add(ref.notifier(settingsProvider).setMinimizeToTray(true));
      if (!settings.quickSaveFromFavorites) {
        futures.add(ref.notifier(settingsProvider).setQuickSaveFromFavorites(true));
      }
      if (checkPlatform([TargetPlatform.windows])) {
        final showInContextMenu = await isContextMenuEnabled();
        if (!showInContextMenu) {
          futures.add(enableContextMenu());
        }
      }
    }

    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final vm = ref.watch(settingsTabControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = provider.Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAuthenticated = authProvider.isAuthenticated;

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
                      t.settingsTab.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : LinkDropColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.settingsTab.subtitle,
                      style: TextStyle(
                        color: LinkDropColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 主内容区域
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children: [
                // 用户信息区域
                SettingsGroup(
                  title: '账户',
                  isDark: isDark,
                  children: [
                    if (isAuthenticated && user != null) ...[
                      SettingsItem(
                        icon: Icons.person,
                        title: user.username,
                        value: user.isVipActive ? 'VIP会员' : '普通用户',
                        isDark: isDark,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.isVipActive ? LinkDropColors.primary.withOpacity(0.1) : LinkDropColors.zinc200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.isVipActive ? 'VIP' : '普通',
                            style: TextStyle(
                              color: user.isVipActive ? LinkDropColors.primary : LinkDropColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SettingsItem(
                        icon: Icons.workspace_premium,
                        title: user.isVipActive ? '续费会员' : '开通会员',
                        value: user.isVipActive ? '剩余${user.vipRemainingDays}天' : '享受更多特权',
                        isDark: isDark,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PaymentPage(),
                              fullscreenDialog: true,
                            ),
                          );
                          await provider.Provider.of<AuthProvider>(context, listen: false).refreshUser();
                          setState(() {});
                        },
                      ),
                      if (user.inviteCode != null)
                        SettingsItem(
                          icon: Icons.card_giftcard,
                          title: '我的邀请码',
                          value: user.inviteCode,
                          isDark: isDark,
                          trailing: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: user.inviteCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('邀请码已复制')),
                              );
                            },
                            child: Icon(Icons.copy, size: 20, color: LinkDropColors.primary),
                          ),
                        ),
                      SettingsItem(
                        icon: Icons.logout,
                        title: '退出登录',
                        isDark: isDark,
                        onTap: () async {
                          await provider.Provider.of<AuthProvider>(context, listen: false).logout();
                          setState(() {});
                        },
                      ),
                    ] else ...[
                      SettingsItem(
                        icon: Icons.login,
                        title: '登录 / 注册',
                        value: '登录后享受更多功能',
                        isDark: isDark,
                        onTap: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                              fullscreenDialog: true,
                            ),
                          );
                          if (result == true) {
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ],
                ),

                // 常规设置
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
                        icon: Icon(Icons.arrow_drop_down, color: LinkDropColors.textSecondary),
                        items: vm.themeModes.map((theme) {
                          return DropdownMenuItem(
                            value: theme,
                            child: Text(
                              theme.humanName,
                              style: TextStyle(
                                color: isDark ? Colors.white : LinkDropColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (theme) => vm.onChangeTheme(context, theme!),
                      ),
                    ),
                  ],
                ),

                // 接收设置
                SettingsGroup(
                  title: t.settingsTab.receive.title,
                  isDark: isDark,
                  children: [
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
                  ],
                ),

                // 网络设置
                SettingsGroup(
                  title: t.settingsTab.network.title,
                  isDark: isDark,
                  children: [
                    SettingsItem(
                      icon: Icons.devices,
                      title: t.settingsTab.network.deviceType,
                      isDark: isDark,
                      trailing: DropdownButton<DeviceType>(
                        value: vm.deviceInfo.deviceType,
                        dropdownColor: isDark ? LinkDropColors.zinc800 : Colors.white,
                        underline: Container(),
                        icon: Icon(Icons.arrow_drop_down, color: LinkDropColors.textSecondary),
                        items: DeviceType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Icon(
                              type.icon,
                              color: isDark ? Colors.white : LinkDropColors.textPrimary,
                            ),
                          );
                        }).toList(),
                        onChanged: (type) async {
                          if (type != null) {
                            await ref.notifier(settingsProvider).setDeviceType(type);
                          }
                        },
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