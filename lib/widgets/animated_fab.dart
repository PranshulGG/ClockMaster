import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../helpers/icon_helper.dart';

class AnimatedFAB extends StatefulWidget {
  final bool isRunning;
  final VoidCallback onPressed;

  const AnimatedFAB({
    super.key,
    required this.isRunning,
    required this.onPressed,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB> {
  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onPressed,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: widget.isRunning ? 50.0 : 28.0,
          end: widget.isRunning ? 28.0 : 50.0,
        ),
        duration: const Duration(milliseconds: 300),
        curve: widget.isRunning ? Curves.easeOutBack : Curves.easeOutBack,
        builder: (context, borderRadiusValue, child) {
          return Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: widget.isRunning
                  ? colorTheme.surfaceContainerHighest
                  : colorTheme.primary,
              borderRadius: BorderRadius.circular(borderRadiusValue),
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: IconWithWeight(
              widget.isRunning ? Symbols.pause : Symbols.play_arrow,
              color: widget.isRunning
                  ? colorTheme.primary
                  : colorTheme.onPrimary,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
