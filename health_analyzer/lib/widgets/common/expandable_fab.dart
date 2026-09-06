import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Expandable Floating Action Button with smooth animations
/// Displays multiple action options when expanded
/// Adapted from Shots Studio for LabLens health tracking
class ExpandableFab extends StatefulWidget {
  /// List of actions to display when expanded
  final List<ExpandableFabAction> actions;

  /// Icon or widget to display on the main FAB
  final Widget? child;

  /// Background color of the main FAB
  final Color? backgroundColor;

  /// Foreground color (icon/text) of the main FAB
  final Color? foregroundColor;

  /// Distance between action buttons
  final double distance;

  /// Duration of expand/collapse animation
  final Duration animationDuration;

  const ExpandableFab({
    super.key,
    required this.actions,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.distance = 100.0,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Smooth expand animation with easing
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Rotate main FAB icon (45 degrees = 1/8 turn)
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Fade in/out for action buttons
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggle expand/collapse state
  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  /// Close FAB and execute action
  void _closeAndExecute(VoidCallback action) {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
      _controller.reverse().then((_) => action());
    } else {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHeight = widget.actions.length * 50.0 + 90;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _expandAnimation.value;
        final currentWidth = 56.0 + (180.0 - 56.0) * progress;
        final currentHeight = 56.0 + (totalHeight - 56.0) * progress;

        return SizedBox(
          width: currentWidth,
          height: currentHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              // Transparent overlay to detect taps outside when expanded
              if (_isExpanded)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),

              // Action buttons
              ...widget.actions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;

                // Calculate position: expand upward and slightly left
                final double spacing = 50.0;
                final double yOffset = -spacing * (index + 1) - 20;
                final double xOffset = -10.0;

                return AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    final progress = _expandAnimation.value;
                    return Transform.translate(
                      offset: Offset(xOffset * progress, yOffset * progress),
                      child: Transform.scale(
                        scale: progress,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(22),
                            color: action.backgroundColor ??
                                theme.colorScheme.secondaryContainer,
                            shadowColor: theme.colorScheme.shadow.withValues(
                              alpha: 0.4,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () => _closeAndExecute(action.onPressed),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                constraints: const BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Label
                                    Flexible(
                                      child: Text(
                                        action.label,
                                        style: TextStyle(
                                          color: action.foregroundColor ??
                                              theme.colorScheme
                                                  .onSecondaryContainer,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Icon
                                    Icon(
                                      action.icon,
                                      size: 18,
                                      color: action.foregroundColor ??
                                          theme
                                              .colorScheme.onSecondaryContainer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              // Main FAB with rotation animation
              Transform.rotate(
                angle: _rotateAnimation.value * 2 * math.pi,
                child: FloatingActionButton(
                  heroTag: "main_fab",
                  backgroundColor:
                      widget.backgroundColor ?? theme.colorScheme.primary,
                  foregroundColor:
                      widget.foregroundColor ?? theme.colorScheme.onPrimary,
                  onPressed: _toggle,
                  elevation: _isExpanded ? 8 : 6,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: _isExpanded
                        ? const Icon(
                            Icons.close,
                            key: ValueKey('close'),
                          )
                        : (widget.child ??
                            const Icon(
                              Icons.add,
                              key: ValueKey('add'),
                            )),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Action item for ExpandableFab
class ExpandableFabAction {
  /// Icon to display
  final IconData icon;

  /// Label text to display
  final String label;

  /// Callback when action is pressed
  final VoidCallback onPressed;

  /// Optional tooltip
  final String? tooltip;

  /// Background color of the action button
  final Color? backgroundColor;

  /// Foreground color (icon/text) of the action button
  final Color? foregroundColor;

  const ExpandableFabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });
}
