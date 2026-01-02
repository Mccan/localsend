import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/receive_history_page.dart';
import 'package:localsend_app/pages/tabs/receive_tab_vm.dart';
import 'package:localsend_app/pages_linkdrop/widget/pulse_ripple.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/ip_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch(receiveTabVmProvider);
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
                      'Receive',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : LinkDropColors.zinc900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready to accept files',
                      style: TextStyle(
                        color: LinkDropColors.zinc500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    context.push(() => const ReceiveHistoryPage());
                  },
                  icon: const Icon(Icons.history),
                  tooltip: 'History',
                  color: LinkDropColors.zinc500,
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                            color: Colors.black.withOpacity(0.1),
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
                    'Ready to Receive',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // IP / Alias Display
                  InkWell(
                    onTap: () {
                      // TODO: Show dialog to edit alias
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
                            vm.localIps.isNotEmpty ? vm.localIps.join(', ') : 'No Network',
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

                  // Quick Save Toggle
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
                          'Quick Save',
                          style: TextStyle(
                            color: isDark ? Colors.white : LinkDropColors.zinc900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: vm.quickSaveSettings,
                          onChanged: (value) => vm.onSetQuickSave(context, value),
                          activeColor: LinkDropColors.teal500,
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
}
