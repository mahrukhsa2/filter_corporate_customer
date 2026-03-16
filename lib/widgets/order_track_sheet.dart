import 'package:flutter/material.dart';
import '../../data/network/api_response.dart';
import '../../data/repositories/order_track_repository.dart';
import '../../models/order_track_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/order_track_sheet.dart
//
// Self-contained, reusable bottom sheet that fetches and displays order
// tracking timeline. Call via:
//
//   OrderTrackSheet.show(context, orderId: '2', bookingCode: 'CB-2');
// ─────────────────────────────────────────────────────────────────────────────

class OrderTrackSheet extends StatefulWidget {
  final String orderId;
  final String bookingCode;

  const OrderTrackSheet({
    super.key,
    required this.orderId,
    required this.bookingCode,
  });

  /// Convenience method — opens as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String bookingCode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderTrackSheet(
        orderId:     orderId,
        bookingCode: bookingCode,
      ),
    );
  }

  @override
  State<OrderTrackSheet> createState() => _OrderTrackSheetState();
}

class _OrderTrackSheetState extends State<OrderTrackSheet> {
  bool             _loading = true;
  String?          _error;
  ApiErrorType     _errorType = ApiErrorType.none;
  OrderTrackModel? _track;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });

    final result = await OrderTrackRepository.fetchTrack(widget.orderId);

    if (!mounted) return;

    if (result.success && result.data != null) {
      setState(() { _track = result.data; _loading = false; });
    } else {
      setState(() {
        _error     = result.message ?? 'Could not load tracking info.';
        _errorType = result.errorType;
        _loading   = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ───────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.track_changes_outlined,
                    color: AppColors.secondaryLight, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Track Booking',
                        style: AppTextStyles.h3
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(widget.bookingCode,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded,
                    color: Colors.grey.shade500),
              ),
            ]),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 8),

          // ── Content ──────────────────────────────────────────────────────
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryLight),
              ),
            )
          else if (_error != null)
            _ErrorContent(
              message:   _error!,
              errorType: _errorType,
              onRetry:   _fetch,
            )
          else if (_track != null)
            _TrackContent(track: _track!)
          else
            const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Track content — branch + timeline
// ─────────────────────────────────────────────────────────────────────────────

class _TrackContent extends StatelessWidget {
  final OrderTrackModel track;
  const _TrackContent({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch + current status pill
          Row(children: [
            Icon(Icons.store_outlined,
                size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(track.branch,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade600)),
            ),
            _StatusPill(status: track.currentStatus),
          ]),

          const SizedBox(height: 20),

          // Timeline
          ...track.timeline.asMap().entries.map((entry) {
            final i    = entry.key;
            final step = entry.value;
            final isLast = i == track.timeline.length - 1;
            return _TimelineStep(item: step, isLast: isLast);
          }),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Close',
              onPressed: () => Navigator.pop(context),
              backgroundColor: AppColors.secondaryLight,
              textColor: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline step — reusable
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final TrackTimelineItem item;
  final bool              isLast;
  const _TimelineStep({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final done = item.completed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Dot + line ────────────────────────────────────────────────────
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.primaryLight
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done
                        ? AppColors.primaryLight
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 15, color: AppColors.onPrimaryLight)
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2, height: 44,
                  color: done
                      ? AppColors.primaryLight.withOpacity(0.35)
                      : Colors.grey.shade200,
                ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        // ── Label + time ──────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: done
                        ? AppColors.onBackgroundLight
                        : Colors.grey.shade400,
                  ),
                ),
                if (item.formattedTime.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.formattedTime,
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.grey.shade500),
                  ),
                ],
                if (!isLast) const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  String get _label => switch (status.toLowerCase()) {
    'submitted'   => 'In Progress',
    'approved'    => 'Approved',
    'in_progress' => 'In Progress',
    'completed'   => 'Completed',
    'cancelled'   => 'Cancelled',
    'invoiced'    => 'Completed',
    _             => status,
  };

  Color get _color => switch (status.toLowerCase()) {
    'completed' || 'invoiced' => Colors.green.shade600,
    'in_progress'             => Colors.blue.shade600,
    'submitted'               => Colors.orange.shade700,
    'approved'                => Colors.teal.shade600,
    'cancelled'               => Colors.red.shade600,
    _                         => Colors.grey.shade600,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.30)),
      ),
      child: Text(_label,
          style: AppTextStyles.caption
              .copyWith(color: _color, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error content
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorContent extends StatelessWidget {
  final String       message;
  final ApiErrorType errorType;
  final VoidCallback onRetry;
  const _ErrorContent({
    required this.message,
    required this.errorType,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded,
                size: 40, color: Colors.red.shade300),
          ),
          const SizedBox(height: 16),
          Text('Could not load tracking',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Retry',
              onPressed: onRetry,
              backgroundColor: AppColors.primaryLight,
              textColor: AppColors.onPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
