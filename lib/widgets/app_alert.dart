import 'package:flutter/material.dart';

import '../data/network/api_response.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/app_alert.dart
// Reusable alert helpers used across the entire app.
//
// Usage examples:
//   AppAlert.error(context, message: 'Something went wrong');
//   AppAlert.apiError(context, errorType: ApiErrorType.noInternet);
//   AppAlert.success(context, message: 'Saved successfully');
//   AppAlert.confirm(context, title: 'Delete?', onConfirm: () { ... });
//   AppAlert.snackbar(context, message: 'Copied!');
// ─────────────────────────────────────────────────────────────────────────────

class AppAlert {

  // ── Colour palette (matches app theme) ────────────────────────────────────
  static const _yellow  = Color(0xFFFCC247);
  static const _dark    = Color(0xFF23262D);
  static const _red     = Color(0xFFC62828);
  static const _green   = Color(0xFF2E7D32);
  static const _orange  = Color(0xFFE65100);

  // ─────────────────────────────────────────────────────────────────────────
  // Error dialog — generic
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> error(
    BuildContext context, {
    required String message,
    String title = 'Error',
    VoidCallback? onDismiss,
  }) {
    return _show(
      context,
      icon:      Icons.error_outline_rounded,
      iconColor: _red,
      title:     title,
      message:   message,
      actions: [
        _AlertAction(
          label:     'OK',
          isPrimary: true,
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // API error dialog — derives title + icon from ApiErrorType automatically
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> apiError(
    BuildContext context, {
    required ApiErrorType errorType,
    String? message,
    VoidCallback? onRetry,
  }) {
    final cfg = _errorConfig(errorType);
    final msg = message?.isNotEmpty == true ? message! : cfg.defaultMessage;

    return _show(
      context,
      icon:      cfg.icon,
      iconColor: cfg.color,
      title:     cfg.title,
      message:   msg,
      actions: [
        if (onRetry != null)
          _AlertAction(
            label:     'Retry',
            isPrimary: false,
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
          ),
        _AlertAction(
          label:     'OK',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Success dialog
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> success(
    BuildContext context, {
    required String message,
    String title = 'Success',
    VoidCallback? onDismiss,
  }) {
    return _show(
      context,
      icon:      Icons.check_circle_outline_rounded,
      iconColor: _green,
      title:     title,
      message:   message,
      actions: [
        _AlertAction(
          label:     'OK',
          isPrimary: true,
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Confirmation dialog
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel  = 'Confirm',
    String cancelLabel   = 'Cancel',
    bool   isDangerous   = false,
  }) {
    return _show(
      context,
      icon:      isDangerous
          ? Icons.warning_amber_rounded
          : Icons.help_outline_rounded,
      iconColor: isDangerous ? _orange : _dark,
      title:     title,
      message:   message,
      actions: [
        _AlertAction(
          label:     cancelLabel,
          isPrimary: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        _AlertAction(
          label:      confirmLabel,
          isPrimary:  true,
          isDanger:   isDangerous,
          onPressed:  () {
            Navigator.of(context).pop();
            onConfirm();
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Snackbar (lightweight, non-blocking)
  // ─────────────────────────────────────────────────────────────────────────

  static void snackbar(
    BuildContext context, {
    required String message,
    bool isError   = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    Color bg;
    IconData icon;
    if (isError) {
      bg   = _red;
      icon = Icons.error_outline_rounded;
    } else if (isSuccess) {
      bg   = _green;
      icon = Icons.check_circle_outline_rounded;
    } else {
      bg   = _dark;
      icon = Icons.info_outline_rounded;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(
            duration:  duration,
            behavior:  SnackBarBehavior.floating,
            backgroundColor: bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color:      Colors.white,
                      fontFamily: 'Manrope',
                      fontSize:   13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private: core dialog builder
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> _show(
    BuildContext context, {
    required IconData        icon,
    required Color           iconColor,
    required String          title,
    required String          message,
    required List<_AlertAction> actions,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AppAlertDialog(
        icon:      icon,
        iconColor: iconColor,
        title:     title,
        message:   message,
        actions:   actions,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private: error type → config mapping
  // ─────────────────────────────────────────────────────────────────────────

  static _ErrorConfig _errorConfig(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.noInternet:
        return _ErrorConfig(
          icon:           Icons.wifi_off_rounded,
          color:          _orange,
          title:          'No Internet',
          defaultMessage: 'No internet connection. Please check your network.',
        );
      case ApiErrorType.timeout:
        return _ErrorConfig(
          icon:           Icons.timer_off_outlined,
          color:          _orange,
          title:          'Request Timed Out',
          defaultMessage: 'The request took too long. Please try again.',
        );
      case ApiErrorType.unauthorized:
        return _ErrorConfig(
          icon:           Icons.lock_outline_rounded,
          color:          _red,
          title:          'Session Expired',
          defaultMessage: 'Your session has expired. Please log in again.',
        );
      case ApiErrorType.forbidden:
        return _ErrorConfig(
          icon:           Icons.block_rounded,
          color:          _red,
          title:          'Access Denied',
          defaultMessage: 'You don\'t have permission to perform this action.',
        );
      case ApiErrorType.notFound:
        return _ErrorConfig(
          icon:           Icons.search_off_rounded,
          color:          _orange,
          title:          'Not Found',
          defaultMessage: 'The requested resource was not found.',
        );
      case ApiErrorType.validation:
        return _ErrorConfig(
          icon:           Icons.warning_amber_rounded,
          color:          _orange,
          title:          'Invalid Input',
          defaultMessage: 'Please check your input and try again.',
        );
      case ApiErrorType.serverError:
        return _ErrorConfig(
          icon:           Icons.dns_outlined,
          color:          _red,
          title:          'Server Error',
          defaultMessage: 'Server error. Please try again later.',
        );
      default:
        return _ErrorConfig(
          icon:           Icons.error_outline_rounded,
          color:          _red,
          title:          'Error',
          defaultMessage: 'Something went wrong. Please try again.',
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private: dialog widget
// ─────────────────────────────────────────────────────────────────────────────

class _AppAlertDialog extends StatelessWidget {
  final IconData           icon;
  final Color              iconColor;
  final String             title;
  final String             message;
  final List<_AlertAction> actions;

  const _AppAlertDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:  iconColor.withOpacity(0.1),
                shape:  BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 16),

            // ── Title ────────────────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily:  'Manrope',
                fontSize:    17,
                fontWeight:  FontWeight.w800,
                color:       Color(0xFF23262D),
              ),
            ),
            const SizedBox(height: 8),

            // ── Message ──────────────────────────────────────────────────
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize:   13,
                color:      Colors.grey.shade600,
                height:     1.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────────
            Row(
              children: actions.map((a) {
                final isOnly = actions.length == 1;
                final btn = _buildButton(a, context);
                return isOnly
                    ? Expanded(child: btn)
                    : Expanded(child: Padding(
                        padding: EdgeInsets.only(
                          left:  actions.indexOf(a) > 0 ? 8 : 0,
                          right: actions.indexOf(a) < actions.length - 1 ? 8 : 0,
                        ),
                        child: btn,
                      ));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(_AlertAction action, BuildContext context) {
    if (action.isPrimary) {
      return SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: action.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: action.isDanger
                ? const Color(0xFFC62828)
                : const Color(0xFF23262D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(
            action.label,
            style: const TextStyle(
                fontFamily:  'Manrope',
                fontWeight:  FontWeight.w700,
                fontSize:    13),
          ),
        ),
      );
    }
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: action.onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF23262D),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          action.label,
          style: const TextStyle(
              fontFamily:  'Manrope',
              fontWeight:  FontWeight.w600,
              fontSize:    13),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

class _AlertAction {
  final String      label;
  final bool        isPrimary;
  final bool        isDanger;
  final VoidCallback onPressed;

  const _AlertAction({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    this.isDanger = false,
  });
}

class _ErrorConfig {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   defaultMessage;

  const _ErrorConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.defaultMessage,
  });
}
