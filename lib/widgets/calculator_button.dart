import 'package:flutter/material.dart';

enum ButtonVariant {
  primary,
  operator,
  secondary,
  zero,
}

class CalculatorButton extends StatelessWidget {
  final String text;
  final ButtonVariant variant;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final bool disabled;

  const CalculatorButton({
    super.key,
    required this.text,
    this.variant = ButtonVariant.primary,
    this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: disabled ? null : (_) => onLongPressStart?.call(),
      onTapUp: disabled ? null : (_) => onLongPressEnd?.call(),
      onTapCancel: onLongPressEnd,
      child: SizedBox(
        height: 80,
        width: variant == ButtonVariant.zero ? 170 : 80,
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getBackgroundColor(),
            foregroundColor: _getTextColor(),
            disabledBackgroundColor: _getDisabledBackgroundColor(),
            disabledForegroundColor: _getDisabledTextColor(),
            padding: EdgeInsets.zero,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: variant == ButtonVariant.zero ? 30 : 34,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case ButtonVariant.operator:
        return const Color(0xFFF97316);
      case ButtonVariant.secondary:
        return const Color(0xFFA3A3A3);
      case ButtonVariant.zero:
        return const Color(0xFF333333);
      case ButtonVariant.primary:
        return const Color(0xFF333333);
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case ButtonVariant.secondary:
        return Colors.black;
      default:
        return Colors.white;
    }
  }

  Color _getDisabledBackgroundColor() {
    switch (variant) {
      case ButtonVariant.secondary:
        return const Color(0xFF737373);
      default:
        return const Color(0xFF1A1A1A);
    }
  }

  Color _getDisabledTextColor() {
    return Colors.white38;
  }
}
