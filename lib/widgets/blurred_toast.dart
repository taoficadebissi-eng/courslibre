import 'dart:ui';
import 'package:flutter/material.dart';

/// Affiche un message centré à l'écran, dans une box noire floutée
/// (effet "glassy"), qui disparaît automatiquement après [duration].
///
/// Usage :
///   BlurredToast.show(context, "Session expirée, reconnectez-vous.");
class BlurredToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    // Retire un toast existant s'il y en a déjà un affiché
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _BlurredToastWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismissed: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _BlurredToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _BlurredToastWidget({
    required this.message,
    required this.duration,
    required this.onDismissed,
    this.icon,
  });

  @override
  State<_BlurredToastWidget> createState() => _BlurredToastWidgetState();
}

class _BlurredToastWidgetState extends State<_BlurredToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Programme la disparition automatique
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        // laisse passer les interactions vers l'écran en dessous
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  type: MaterialType.transparency,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
