import 'dart:math';
import 'package:flutter/material.dart';

enum OverlayType { correct, wrong, timeout }

class CorrectnessOverlay extends StatefulWidget {
  final OverlayType type;
  final VoidCallback onFinish;

  const CorrectnessOverlay({
    super.key,
    required this.type,
    required this.onFinish,
  });

  @override
  State<CorrectnessOverlay> createState() => _CorrectnessOverlayState();
}

class _CorrectnessOverlayState extends State<CorrectnessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _fall; // 用于时间到下落动画

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 答对 & 时间到动画：缩放
    _scale = Tween<double>(begin: 0.7, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // 全部动画淡出
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );

    // 时间到动画下落偏移
    _fall = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().whenComplete(() => widget.onFinish());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _text {
    switch (widget.type) {
      case OverlayType.correct:
        return "答对了！";
      case OverlayType.wrong:
        return "答错了！";
      case OverlayType.timeout:
        return "时间到！";
    }
  }

  Color get _color {
    switch (widget.type) {
      case OverlayType.correct:
        return Colors.greenAccent;
      case OverlayType.wrong:
        return Colors.redAccent;
      case OverlayType.timeout:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            double offsetX = 0;

            // 答错抖动
            if (widget.type == OverlayType.wrong) {
              offsetX = sin(_controller.value * pi * 10) * 8; // ±8px抖动
            }

            // 时间到下落
            double offsetY = 0;
            if (widget.type == OverlayType.timeout) {
              offsetY = _fall.value;
            }

            return Transform.translate(
              offset: Offset(offsetX, offsetY),
              child: Transform.scale(
                scale: widget.type != OverlayType.wrong ? _scale.value : 1.0,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(2, 2),
                )
              ],
            ),
            child: Text(
              _text,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
