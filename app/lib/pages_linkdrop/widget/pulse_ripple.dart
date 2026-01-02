import 'package:flutter/material.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';

class PulseRipple extends StatefulWidget {
  final Widget child;
  final Color color;

  const PulseRipple({
    required this.child,
    required this.color,
    super.key,
  });

  @override
  State<PulseRipple> createState() => _PulseRippleState();
}

class _PulseRippleState extends State<PulseRipple> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple 1
        _buildRipple(0),
        // Ripple 2
        _buildRipple(0.5),
        widget.child,
      ],
    );
  }

  Widget _buildRipple(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = (_controller.value + delay) % 1.0;
        return Opacity(
          opacity: (1.0 - value) * 0.5,
          child: Transform.scale(
            scale: 1.0 + (value * 0.5), // Scale from 1.0 to 1.5
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.2),
              ),
            ),
          ),
        );
      },
    );
  }
}
