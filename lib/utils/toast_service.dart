import 'dart:async';
import 'package:flutter/material.dart';

class ToastService {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, 'Success', Colors.green.shade800);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, 'Error', const Color(0xFFB71C1C));
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, 'Info', Colors.blue.shade800);
  }

  static void _show(BuildContext context, String message, String title, Color titleColor) {
    _currentEntry?.remove();
    _timer?.cancel();

    final overlay = Overlay.of(context);
    _currentEntry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        title: title,
        message: message,
        titleColor: titleColor,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);
    _timer = Timer(const Duration(seconds: 3), () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final Color titleColor;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.title,
    required this.message,
    required this.titleColor,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 20;
    return Positioned(
      top: topPadding,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: TextStyle(
                          color: widget.titleColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.2)),
                  const SizedBox(height: 4),
                  Text(widget.message,
                      style: const TextStyle(
                          color: Color(0xFF23262D),
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
