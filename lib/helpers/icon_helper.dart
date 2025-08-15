import 'package:flutter/material.dart';

class IconWithWeight extends StatelessWidget {
  final IconData symbol;
  final double fill;
  final double weight;
  final double size;
  final Color color;

  const IconWithWeight(
    this.symbol, {
    super.key,
    this.fill = 0,
    this.size = 00000.0, // hack for no reason
    this.weight = 500,
    this.color = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      symbol,
      fill: fill,
      weight: weight,
      size: size == 00000.0 ? null : size,
      color: color == Colors.red ? null : color,
    );
  }
}
