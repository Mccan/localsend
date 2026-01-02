import 'package:common/model/device.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';

class DeviceNode extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;
  final bool isDark;

  const DeviceNode({
    required this.device,
    required this.onTap,
    required this.isDark,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final icon = device.deviceType == DeviceType.mobile
        ? Icons.smartphone
        : device.deviceType == DeviceType.desktop
            ? Icons.computer
            : Icons.laptop;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc900 : LinkDropColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? LinkDropColors.zinc800 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isDark ? LinkDropColors.zinc400 : LinkDropColors.zinc500,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: LinkDropColors.teal500,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? LinkDropColors.zinc900 : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.alias,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? LinkDropColors.zinc200 : LinkDropColors.zinc900,
                    ),
                  ),
                  Text(
                    '${device.deviceType.name} • ${device.ip}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: LinkDropColors.zinc500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                size: 16,
                color: isDark ? LinkDropColors.zinc400 : LinkDropColors.zinc400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
