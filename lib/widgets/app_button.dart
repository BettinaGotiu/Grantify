import 'package:flutter/material.dart';
import '../core/app_style.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.backgroundColor = AppStyle.primaryYellow,
    this.textColor = Colors.black,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.loading;
    
    // When pressed, the offset of the solid shadow shrinks, giving a "pressed-down" 3D effect.
    final double currentOffset = _isPressed ? 1.0 : 4.0;

    return Opacity(
      opacity: isDisabled ? 0.75 : 1.0,
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: isDisabled ? null : (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: double.infinity,
          height: 52,
          // Move the button container closer to the shadow origin to simulate physical press
          transform: Matrix4.translationValues(4.0 - currentOffset, 4.0 - currentOffset, 0.0),
          decoration: AppStyle.cartoonDecoration(
            color: isDisabled ? Colors.grey[300]! : widget.backgroundColor,
            borderRadius: 12.0,
            shadowOffset: Offset(currentOffset, currentOffset),
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: widget.textColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
