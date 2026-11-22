import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The night sky background with soft glowing colour blobs.
/// The blobs give the frosted glass panels something to blur, which is what
/// makes the glass effect visible.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, AppColors.ink, Color(0xFF0A1F2E)],
              ),
            ),
          ),
        ),
        const _Glow(alignment: Alignment(-1.2, -0.9), color: AppColors.blue, size: 340),
        const _Glow(alignment: Alignment(1.3, -0.3), color: AppColors.violet, size: 300),
        const _Glow(alignment: Alignment(-0.8, 1.2), color: AppColors.mint, size: 320),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.alignment, required this.color, required this.size});

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// A frosted glass panel: blurs whatever is behind it, adds a light tint
/// and a thin bright border, like a sheet of glass.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.radius = 24,
    this.blur = 18,
    this.tint,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final double blur;

  /// Optional accent colour mixed into the glass.
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final accent = tint ?? Colors.white;

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: tint == null ? 0.14 : 0.28),
                    accent.withValues(alpha: tint == null ? 0.04 : 0.08),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A scaffold with the glass background and a see through app bar.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: title == null && actions == null
            ? null
            : AppBar(
                title: title == null
                    ? null
                    : Text(title!, style: const TextStyle(fontWeight: FontWeight.w700)),
                actions: actions,
              ),
        floatingActionButton: floatingActionButton,
        body: body,
      ),
    );
  }
}

/// A small rounded icon badge used in lists and buttons.
class GlassIconBadge extends StatelessWidget {
  const GlassIconBadge({super.key, required this.icon, this.color = AppColors.cyan, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size / 3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
