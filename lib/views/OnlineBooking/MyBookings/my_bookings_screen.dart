import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/booking_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import 'my_bookings_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyBookingsViewModel(),
      child: const _MyBookingsBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _MyBookingsBody extends StatelessWidget {
  const _MyBookingsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyBookingsViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(title: "My Bookings", showBackButton: true,),
          if (vm.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight,
                ),
              ),
            )
          else if (vm.bookings.isEmpty)
            const Expanded(child: _EmptyState())
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.refresh,
                color: AppColors.primaryLight,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 24 : 16,
                    20,
                    isWide ? 24 : 16,
                    40,
                  ),
                  child: isWide
                      ? _WideLayout(bookings: vm.bookings)
                      : _NarrowLayout(bookings: vm.bookings),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layouts
// ─────────────────────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final List<BookingHistoryModel> bookings;
  const _NarrowLayout({required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: bookings
          .map((booking) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _BookingCard(booking: booking),
              ))
          .toList(),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final List<BookingHistoryModel> bookings;
  const _WideLayout({required this.bookings});

  @override
  Widget build(BuildContext context) {
    // Group bookings in pairs for two-column layout
    final pairs = <List<BookingHistoryModel>>[];
    for (int i = 0; i < bookings.length; i += 2) {
      if (i + 1 < bookings.length) {
        pairs.add([bookings[i], bookings[i + 1]]);
      } else {
        pairs.add([bookings[i]]);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: pairs.map((pair) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _BookingCard(booking: pair[0])),
              if (pair.length > 1) ...[
                const SizedBox(width: 20),
                Expanded(child: _BookingCard(booking: pair[1])),
              ] else
                const Spacer(),
            ],
          ),
        );
      }).toList(),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Booking Card
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingHistoryModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: Service name + Date ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  size: 22,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(width: 12),
              // Service name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackgroundLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.formattedDate,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          // ── Branch location ─────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.branchName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Status badge ────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(booking.status).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(booking.status),
                      size: 14,
                      color: _getStatusColor(booking.status),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      booking.status,
                      style: AppTextStyles.caption.copyWith(
                        color: _getStatusColor(booking.status),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Invoice & Amount (only for completed) ───────────────────
          if (booking.invoiceNumber != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  'Invoice ${booking.invoiceNumber}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'SAR ${_formatAmount(booking.amount ?? 0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onBackgroundLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // ── Action buttons ──────────────────────────────────────────
          _buildActionButtons(context, booking),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, BookingHistoryModel booking) {
    if (booking.status == 'Completed' && booking.invoiceNumber != null) {
      // Completed: View Invoice, Pay from Wallet (if unpaid), Download
      final isWide = MediaQuery.of(context).size.width > 720;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ActionButton(
            label: 'View Invoice',
            icon: Icons.visibility_outlined,
            onTap: () => _showInvoice(context, booking),
            isPrimary: false,
          ),
          if (!booking.isPaid)
            _ActionButton(
              label: 'Pay from Wallet',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => _payFromWallet(context, booking),
              isPrimary: true,
            ),
          _ActionButton(
            label: 'Download',
            icon: Icons.download_rounded,
            onTap: () => _downloadInvoice(context, booking),
            isPrimary: false,
          ),
        ],
      );
    } else if (booking.status == 'In Progress') {
      // In Progress: Track Status
      return _ActionButton(
        label: 'Track Status',
        icon: Icons.track_changes_outlined,
        onTap: () => _trackStatus(context, booking),
        isPrimary: true,
        fullWidth: true,
      );
    } else if (booking.status == 'Upcoming') {
      // Upcoming: View Details, Cancel
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ActionButton(
            label: 'View Details',
            icon: Icons.info_outline_rounded,
            onTap: () => _viewDetails(context, booking),
            isPrimary: false,
          ),
          _ActionButton(
            label: 'Cancel Booking',
            icon: Icons.cancel_outlined,
            onTap: () => _cancelBooking(context, booking),
            isPrimary: false,
            isDestructive: true,
          ),
        ],
      );
    } else {
      // Cancelled or other: No actions
      return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.orange;
      case 'In Progress':
        return Colors.orange;
      case 'Upcoming':
        return Colors.orange;
      case 'Cancelled':
        return Colors.black;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle_outline;
      case 'In Progress':
        return Icons.pending_outlined;
      case 'Upcoming':
        return Icons.schedule_outlined;
      case 'Cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }

  // ── Action handlers ────────────────────────────────────────────────────
  void _showInvoice(BuildContext context, BookingHistoryModel booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening invoice ${booking.invoiceNumber}...'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _payFromWallet(BuildContext context, BookingHistoryModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Pay from Wallet',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Pay SAR ${_formatAmount(booking.amount ?? 0)} for invoice ${booking.invoiceNumber}?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Payment processed successfully!'),
                  backgroundColor: AppColors.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.onPrimaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                Text('Pay', style: AppTextStyles.button.copyWith(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _downloadInvoice(BuildContext context, BookingHistoryModel booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📥 Downloading invoice...'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _trackStatus(BuildContext context, BookingHistoryModel booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes_outlined,
                    color: AppColors.primaryLight, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Tracking: ${booking.serviceName}',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _TrackingStep(
              title: 'Booking Confirmed',
              subtitle: booking.formattedDate,
              isCompleted: true,
            ),
            _TrackingStep(
              title: 'Service In Progress',
              subtitle: 'Technician assigned',
              isCompleted: true,
              isCurrent: true,
            ),
            _TrackingStep(
              title: 'Quality Check',
              subtitle: 'Pending',
              isCompleted: false,
            ),
            _TrackingStep(
              title: 'Ready for Pickup',
              subtitle: 'Pending',
              isCompleted: false,
              isLast: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Close',
                onPressed: () => Navigator.pop(ctx),
                backgroundColor: AppColors.secondaryLight,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewDetails(BuildContext context, BookingHistoryModel booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primaryLight, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Booking Details',
                    style:
                        AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Service', value: booking.serviceName),
            _DetailRow(label: 'Date', value: booking.formattedDate),
            _DetailRow(label: 'Branch', value: booking.branchName),
            _DetailRow(label: 'Status', value: booking.status),
            if (booking.vehicleInfo != null)
              _DetailRow(label: 'Vehicle', value: booking.vehicleInfo!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Close',
                onPressed: () => Navigator.pop(ctx),
                backgroundColor: AppColors.secondaryLight,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelBooking(BuildContext context, BookingHistoryModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Booking',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Booking',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Booking cancelled'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Cancel Booking',
                style: AppTextStyles.button.copyWith(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;
  final bool fullWidth;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDestructive
        ? Colors.red.shade50
        : isPrimary
            ? AppColors.primaryLight
            : AppColors.backgroundLight;
    final textColor = isDestructive
        ? Colors.red.shade700
        : isPrimary
            ? AppColors.onPrimaryLight
            : AppColors.onBackgroundLight;
    final borderColor = isDestructive
        ? Colors.red.shade200
        : isPrimary
            ? AppColors.primaryLight
            : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isPrimary ? 0 : 1),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tracking Step Widget
// ─────────────────────────────────────────────────────────────────────────────

class _TrackingStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const _TrackingStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.isCurrent = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primaryLight
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primaryLight
                      : isCompleted
                          ? AppColors.primaryLight
                          : Colors.grey.shade300,
                  width: isCurrent ? 3 : 1,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: AppColors.onPrimaryLight)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? AppColors.primaryLight.withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCompleted || isCurrent
                      ? AppColors.onBackgroundLight
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Row Widget
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onBackgroundLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 80,
                color: AppColors.primaryLight.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Bookings Yet',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onBackgroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your service bookings will appear here',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Book a Service',
              onPressed: () {
                // Navigate to booking screen
                Navigator.pop(context);
              },
              backgroundColor: AppColors.primaryLight,
              textColor: AppColors.onPrimaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
