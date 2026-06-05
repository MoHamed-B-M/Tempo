import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme_extensions.dart';

class ExpressiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;

  const ExpressiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 16,
  });

  @override
  State<ExpressiveButton> createState() => _ExpressiveButtonState();
}

class _ExpressiveButtonState extends State<ExpressiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.3, 0.0, 0.8, 0.15),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = Theme.of(context).extension<ExpressiveMotion>();
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel:
          widget.onPressed != null ? () => _controller.reverse() : null,
      child: Animate(
        effects: [
          ScaleEffect(
            begin: const Offset(1, 1),
            end: const Offset(1.02, 1.02),
            duration: motion?.emphasizedDuration ?? const Duration(milliseconds: 500),
            curve: motion?.emphasizedDecelerate ?? const Cubic(0.05, 0.7, 0.1, 1.0),
          ),
          ShimmerEffect(
            duration: const Duration(seconds: 2),
            color: cs.primary.withValues(alpha: 0.08),
          ),
        ],
        delay: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? cs.primary,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: (widget.backgroundColor ?? cs.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'RobotoFlex',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.foregroundColor ?? cs.onPrimary,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
