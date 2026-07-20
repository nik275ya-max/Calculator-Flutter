import 'package:flutter/material.dart';

class CalculatorDisplay extends StatelessWidget {
  final String value;
  final bool isBlocked;

  const CalculatorDisplay({
    super.key,
    required this.value,
    this.isBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = _calculateFontSize(screenWidth);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          height: 1.1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  double _calculateFontSize(double screenWidth) {
    if (value.length <= 6) return 80;
    if (value.length <= 8) return 64;
    if (value.length <= 10) return 52;
    if (value.length <= 12) return 44;
    return 36;
  }
}
