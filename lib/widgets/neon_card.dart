import 'package:flutter/material.dart';
import '../core/app_style.dart';

class NeonCard extends StatelessWidget {
  const NeonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppStyle.cartoonDecoration(
        color: color,
        borderRadius: 12.0,
      ),
      child: child,
    );
  }
}
