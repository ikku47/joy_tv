import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ErrorOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const ErrorOverlay({
    super.key,
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 380),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 28 : 0),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.red,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stream Unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ErrorButton(
                          label: 'Go Back',
                          icon: Icons.arrow_back_rounded,
                          onTap: onBack,
                          filled: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ErrorButton(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
                          onTap: onRetry,
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _ErrorButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  State<_ErrorButton> createState() => _ErrorButtonState();
}

class _ErrorButtonState extends State<_ErrorButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: widget.filled
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: widget.filled
                ? null
                : Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.filled ? Colors.white : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.filled ? Colors.white : Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
