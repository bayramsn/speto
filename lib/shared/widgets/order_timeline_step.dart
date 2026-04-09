import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

class OrderTimelineStep extends StatelessWidget {
  const OrderTimelineStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.completed,
    this.showLine = true,
  });

  final String title;
  final String subtitle;
  final bool active;
  final bool completed;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = completed
        ? Palette.green
        : active
        ? Palette.red
        : Palette.faint;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 24,
          child: Column(
            children: <Widget>[
              if (active)
                _PulsingTimelineDot(color: dotColor)
              else
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: completed
                        ? Palette.green
                        : dotColor.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: completed
                      ? const Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: Colors.white,
                        )
                      : null,
                ),
              if (showLine)
                Container(
                  width: 2,
                  height: 42,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                    color: active ? Colors.white : Palette.soft,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Palette.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PulsingTimelineDot extends StatefulWidget {
  const _PulsingTimelineDot({required this.color});

  final Color color;

  @override
  State<_PulsingTimelineDot> createState() => _PulsingTimelineDotState();
}

class _PulsingTimelineDotState extends State<_PulsingTimelineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (BuildContext context, Widget? child) {
        final double scale = 1.0 + _anim.value * 0.3;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5 * _anim.value),
                  blurRadius: 8 + _anim.value * 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
