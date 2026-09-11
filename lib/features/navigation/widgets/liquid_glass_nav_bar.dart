import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiquidGlassNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LiquidGlassNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class LiquidGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavBarItem> items;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  double _currentContinuousIndex = 0.0;
  double _previousIndex = 0.0;
  double _targetIndex = 0.0;

  bool _isDragging = false;
  double _dragVelocity = 0.0;
  int _lastHapticIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentContinuousIndex = widget.currentIndex.toDouble();
    _previousIndex = widget.currentIndex.toDouble();
    _targetIndex = widget.currentIndex.toDouble();
    _lastHapticIndex = widget.currentIndex;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _animController.addListener(() {
      if (!_isDragging) {
        setState(() {
          _currentContinuousIndex = _slideAnimation.value;
        });
      }
    });

    _setupAnimation();
  }

  void _setupAnimation() {
    _slideAnimation = Tween<double>(
      begin: _previousIndex,
      end: _targetIndex,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.currentIndex != widget.currentIndex) {
      _animateTo(widget.currentIndex.toDouble());
    }
  }

  void _animateTo(double target) {
    _previousIndex = _currentContinuousIndex;
    _targetIndex = target;
    _setupAnimation();
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _localXToStartDistance(double localX, double totalWidth, bool isRtl) {
    return isRtl ? (totalWidth - localX) : localX;
  }

  void _onTapUp(TapUpDetails details, double totalWidth, bool isRtl) {
    final totalItems = widget.items.length;
    final itemWidth = totalWidth / totalItems;
    final startDist = _localXToStartDistance(details.localPosition.dx, totalWidth, isRtl);
    final tappedIndex = (startDist / itemWidth).floor().clamp(0, totalItems - 1);
    _handleTap(tappedIndex);
  }

  void _onHorizontalDragStart(DragStartDetails details, double totalWidth, bool isRtl) {
    _isDragging = true;
    _animController.stop();
    _updateDragPosition(details.localPosition.dx, totalWidth, isRtl);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double totalWidth, bool isRtl) {
    _dragVelocity = details.primaryDelta ?? 0.0;
    _updateDragPosition(details.localPosition.dx, totalWidth, isRtl);
  }

  void _onHorizontalDragEnd(DragEndDetails details, double totalWidth, bool isRtl) {
    _isDragging = false;
    _dragVelocity = 0.0;
    final totalItems = widget.items.length;
    final target = _currentContinuousIndex.round().clamp(0, totalItems - 1);

    if (target != widget.currentIndex) {
      widget.onTap(target);
    }
    _animateTo(target.toDouble());
  }

  void _updateDragPosition(double localX, double totalWidth, bool isRtl) {
    final totalItems = widget.items.length;
    final itemWidth = totalWidth / totalItems;
    final startDist = _localXToStartDistance(localX, totalWidth, isRtl);

    // Continuous index in logical space [0.0 .. totalItems - 1]
    final continuousIndex = ((startDist / itemWidth) - 0.5).clamp(0.0, totalItems - 1.0);

    final nearestInt = continuousIndex.round().clamp(0, totalItems - 1);
    if (nearestInt != _lastHapticIndex) {
      _lastHapticIndex = nearestInt;
      HapticFeedback.selectionClick();
    }

    setState(() {
      _currentContinuousIndex = continuousIndex;
    });
  }

  void _handleTap(int index) {
    HapticFeedback.selectionClick();
    widget.onTap(index);
    _animateTo(index.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final isRtl = textDirection == TextDirection.rtl;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPadding > 0 ? bottomPadding : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: const Color(0xFF7CFF01).withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalItems = widget.items.length;
                final totalWidth = constraints.maxWidth;
                final itemWidth = totalWidth / totalItems;
                final pillHeight = constraints.maxHeight - 12;

                // Dynamic stretching when moving between items
                final basePillWidth = itemWidth + 14;
                final fractionalPart = (_currentContinuousIndex - _currentContinuousIndex.floor()).abs();
                final midpointStretch = math.sin(fractionalPart * math.pi);
                final velocityStretch = (_dragVelocity.abs() * 0.05).clamp(0.0, 0.4);

                final stretchFactor = 1.0 + (0.95 * midpointStretch) + velocityStretch;
                final pillWidth = (basePillWidth * stretchFactor).clamp(basePillWidth, itemWidth * 2.2);

                // Start offset in directional coordinates (start = 0 at leading edge)
                final centerStart = (_currentContinuousIndex + 0.5) * itemWidth;
                final pillStart = (centerStart - (pillWidth / 2))
                    .clamp(2.0, totalWidth - pillWidth - 2.0);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _onTapUp(d, totalWidth, isRtl),
                  onHorizontalDragStart: (d) => _onHorizontalDragStart(d, totalWidth, isRtl),
                  onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(d, totalWidth, isRtl),
                  onHorizontalDragEnd: (d) => _onHorizontalDragEnd(d, totalWidth, isRtl),
                  onHorizontalDragCancel: () {
                    _isDragging = false;
                    _animateTo(widget.currentIndex.toDouble());
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Moving Liquid Glass Pill Indicator (Directional: matches LTR & RTL naturally)
                      Positioned.directional(
                        textDirection: textDirection,
                        start: pillStart,
                        top: 6,
                        width: pillWidth,
                        height: pillHeight,
                        child: _LiquidGlassPill(
                          isStretched: stretchFactor > 1.2,
                        ),
                      ),

                      // 2. Navigation Items Row
                      Row(
                        children: List.generate(totalItems, (index) {
                          final item = widget.items[index];

                          // Distance from current continuous index in logical space
                          final dist = (_currentContinuousIndex - index).abs();
                          final proximity = (1.0 - (dist / 1.15)).clamp(0.0, 1.0);
                          final edgeRefraction = math.sin(proximity * math.pi);

                          return Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _RefractedNavItem(
                                item: item,
                                proximity: proximity,
                                edgeRefraction: edgeRefraction,
                                tiltDirection: (_currentContinuousIndex - index).clamp(-1.0, 1.0),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// An individual nav item with chromatic aberration and optical refraction
class _RefractedNavItem extends StatelessWidget {
  final LiquidGlassNavBarItem item;
  final double proximity;
  final double edgeRefraction;
  final double tiltDirection;

  const _RefractedNavItem({
    required this.item,
    required this.proximity,
    required this.edgeRefraction,
    required this.tiltDirection,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + (0.16 * proximity);

    // Completely outside the glass pill
    if (proximity <= 0.02) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: 22,
            color: Colors.white.withValues(alpha: 0.60),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.60),
            ),
          ),
        ],
      );
    }

    // Chromatic aberration fringes and optical refraction
    final chromaticOffset = edgeRefraction * 2.8;
    final skewAngle = tiltDirection * edgeRefraction * 0.12;

    final List<Shadow> chromaticShadows = [];
    if (chromaticOffset > 0.3) {
      chromaticShadows.add(
        Shadow(
          offset: Offset(-chromaticOffset, 0.4),
          color: const Color(0xFF00E5FF).withValues(alpha: 0.85 * proximity),
          blurRadius: 1.2,
        ),
      );
      chromaticShadows.add(
        Shadow(
          offset: Offset(chromaticOffset, -0.4),
          color: const Color(0xFFFF0055).withValues(alpha: 0.85 * proximity),
          blurRadius: 1.2,
        ),
      );
    }
    if (proximity > 0.25) {
      chromaticShadows.add(
        Shadow(
          color: const Color(0xFF7CFF01).withValues(alpha: 0.50 * proximity),
          blurRadius: 10,
        ),
      );
    }

    final primaryColor = Color.lerp(
      Colors.white.withValues(alpha: 0.60),
      const Color(0xFFBFFF00), // Vibrant neon lime
      proximity,
    )!;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(scale, scale, 1.0)
        ..rotateZ(skewAngle),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            proximity > 0.4 ? item.activeIcon : item.icon,
            size: 22,
            color: primaryColor,
            shadows: chromaticShadows.isNotEmpty ? chromaticShadows : null,
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: proximity > 0.3 ? FontWeight.bold : FontWeight.w500,
              color: primaryColor,
              shadows: chromaticShadows.isNotEmpty ? chromaticShadows : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The Liquid Glass active indicator with iridescent refraction outline, specular gloss,
/// and internal refraction caustics.
class _LiquidGlassPill extends StatelessWidget {
  final bool isStretched;

  const _LiquidGlassPill({
    this.isStretched = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: 0.16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7CFF01).withValues(alpha: 0.28),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
                blurRadius: 16,
              ),
              BoxShadow(
                color: const Color(0xFFE040FB).withValues(alpha: 0.12),
                blurRadius: 14,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _LiquidGlassPainter(isStretched: isStretched),
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassPainter extends CustomPainter {
  final bool isStretched;

  _LiquidGlassPainter({this.isStretched = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));

    // 1. Iridescent Chromatic Dispersion Rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF7CFF01), // Neon lime
          Color(0xFF00E5FF), // Electric cyan
          Color(0xFFE040FB), // Magenta / purple
          Color(0xFFFFEA00), // Pure yellow
          Color(0xFF00E676), // Spring green
          Color(0xFFFF3D00), // Prismatic orange/red
          Color(0xFF7CFF01), // Loop to neon lime
        ],
        stops: [0.0, 0.20, 0.40, 0.60, 0.78, 0.90, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, rimPaint);

    // 2. Specular Top Light Reflection
    final topHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));

    final topRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.2, 0.8, size.width - 2.4, size.height * 0.5),
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(topRRect, topHighlightPaint);

    // 3. Internal Refraction Caustic Arcs
    final causticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.45),
          const Color(0xFF7CFF01).withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect);

    final causticPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.85,
        size.width * 0.85,
        size.height * 0.75,
      );

    canvas.drawPath(causticPath, causticPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter oldDelegate) =>
      oldDelegate.isStretched != isStretched;
}
