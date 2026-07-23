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
    return Listener(
      onPointerDown: disabled ? null : (_) => onLongPressStart?.call(),
      onPointerUp: disabled ? null : (_) => onLongPressEnd?.call(),
      onPointerCancel: (_) => onLongPressEnd?.call(),
      child: SizedBox(
        height: 80,
        width: variant == ButtonVariant.zero ? 170 : 80,
        child: Container(
          decoration: BoxDecoration(
            color: disabled ? _getDisabledBackgroundColor() : _getBackgroundColor(),
            borderRadius: const BorderRadius.all(Radius.circular(40)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: disabled ? null : onPressed,
              borderRadius: const BorderRadius.all(Radius.circular(40)),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: variant == ButtonVariant.zero ? 30 : 34,
                    fontWeight: FontWeight.w400,
                    color: disabled ? _getDisabledTextColor() : _getTextColor(),
                  ),
                ),
              ),
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
