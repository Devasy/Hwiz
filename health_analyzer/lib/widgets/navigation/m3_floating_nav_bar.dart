import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Navigation item definition for M3FloatingNavBar
class M3FloatingNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const M3FloatingNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  IconData iconFor(bool active) => active ? (activeIcon ?? icon) : icon;
}

/// Material 3 styled floating navigation bar without glassmorphism.
/// Follows pure M3 surface elevation, color schemes, and AMOLED themes.
class M3FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<M3FloatingNavItem> items;

  const M3FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : assert(items.length >= 2, 'M3FloatingNavBar requires at least 2 items.');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final bottomInset = bottomPad + 12;

    final bgColor = cs.surfaceContainer;
    final borderColor = cs.outlineVariant.withValues(alpha: 0.5);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _M3NavChip(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                ),
                if (i < items.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _M3NavChip extends StatefulWidget {
  final M3FloatingNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _M3NavChip({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  State<_M3NavChip> createState() => _M3NavChipState();
}

class _M3NavChipState extends State<_M3NavChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this)
      ..value = widget.active ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(_M3NavChip old) {
    super.didUpdateWidget(old);
    if (old.active == widget.active) return;

    if (widget.active) {
      _ctrl.animateWith(
        SpringSimulation(
          const SpringDescription(
            mass: 1.0,
            stiffness: 180.0,
            damping: 18.0,
          ),
          _ctrl.value,
          1.0,
          0.0,
        ),
      );
    } else {
      _ctrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final progress = _ctrl.value.clamp(0.0, 1.0);
          final labelOpacity = ((progress - 0.4) * 1.66).clamp(0.0, 1.0);
          final extraWidth = progress * 75.0;

          final chipBg = Color.lerp(
            Colors.transparent,
            cs.secondaryContainer,
            progress,
          );

          final iconColor = Color.lerp(
            cs.onSurfaceVariant,
            cs.onSecondaryContainer,
            progress,
          )!;

          return Container(
            height: 48,
            width: 52 + extraWidth,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Center(
                        child: Icon(
                          widget.item.iconFor(widget.active),
                          size: 24,
                          color: iconColor,
                        ),
                      ),
                    ),
                    if (extraWidth > 5.0) ...[
                      Opacity(
                        opacity: labelOpacity,
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
