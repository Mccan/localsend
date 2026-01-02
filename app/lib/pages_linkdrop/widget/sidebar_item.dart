import 'package:flutter/material.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';

class SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.isDark,
    super.key,
  });

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isActiveOrHover = widget.active || _isHovering;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActiveOrHover
                ? (widget.isDark ? LinkDropColors.zinc800 : LinkDropColors.teal500)
                : Colors.transparent,
            boxShadow: (widget.active && !widget.isDark)
                ? [
                    BoxShadow(
                      color: LinkDropColors.teal500.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: isActiveOrHover
                    ? Colors.white
                    : (widget.isDark ? LinkDropColors.zinc500 : LinkDropColors.zinc500),
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isActiveOrHover
                      ? Colors.white
                      : (widget.isDark ? LinkDropColors.zinc200 : LinkDropColors.zinc900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
