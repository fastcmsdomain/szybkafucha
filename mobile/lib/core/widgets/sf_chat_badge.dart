import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/unread_messages_provider.dart';
import '../theme/theme.dart';

/// Wraps any widget (button) with a red unread message badge.
/// Shows a count when unread > 0, with a pop animation on new messages.
class SFChatBadge extends ConsumerStatefulWidget {
  final String taskId;
  final Widget child;

  const SFChatBadge({
    super.key,
    required this.taskId,
    required this.child,
  });

  @override
  ConsumerState<SFChatBadge> createState() => _SFChatBadgeState();
}

class _SFChatBadgeState extends ConsumerState<SFChatBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(taskUnreadCountProvider(widget.taskId));

    // Trigger pop animation when count increases
    if (count > _prevCount && count > 0) {
      _prevCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward(from: 0);
        }
      });
    } else {
      _prevCount = count;
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (count > 0)
          Positioned(
            top: -6,
            right: -6,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
