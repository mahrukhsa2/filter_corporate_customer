// ─────────────────────────────────────────────────────────────────────────────
// lib/models/order_track_model.dart
//
// Response: GET /corporate/orders/{orderId}/track
// {
//   "success": true,
//   "id": "2",
//   "current_status": "submitted",
//   "branch": "Qatar Branch",
//   "booking_code": "CB-2",
//   "timeline": [
//     { "status": "submitted", "label": "Booking Received",
//       "time": "2026-03-08T16:49:58.792Z", "completed": true }
//   ]
// }
// ─────────────────────────────────────────────────────────────────────────────

class OrderTrackModel {
  final String               id;
  final String               currentStatus;
  final String               branch;
  final String               bookingCode;
  final List<TrackTimelineItem> timeline;

  const OrderTrackModel({
    required this.id,
    required this.currentStatus,
    required this.branch,
    required this.bookingCode,
    required this.timeline,
  });

  factory OrderTrackModel.fromMap(Map<String, dynamic> map) {
    final list = map['timeline'] as List<dynamic>? ?? [];
    return OrderTrackModel(
      id:            map['id']?.toString() ?? '',
      currentStatus: map['current_status']?.toString() ?? '',
      branch:        map['branch']?.toString() ?? '',
      bookingCode:   map['booking_code']?.toString() ?? '',
      timeline:      list.map((e) =>
          TrackTimelineItem.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }
}

class TrackTimelineItem {
  final String  status;
  final String  label;
  final DateTime? time;
  final bool    completed;

  const TrackTimelineItem({
    required this.status,
    required this.label,
    this.time,
    required this.completed,
  });

  factory TrackTimelineItem.fromMap(Map<String, dynamic> map) {
    DateTime? time;
    try {
      if (map['time'] != null) time = DateTime.parse(map['time'].toString());
    } catch (_) {}

    return TrackTimelineItem(
      status:    map['status']?.toString() ?? '',
      label:     map['label']?.toString() ?? '',
      time:      time,
      completed: map['completed'] as bool? ?? false,
    );
  }

  String get formattedTime {
    if (time == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = time!.hour.toString().padLeft(2, '0');
    final m = time!.minute.toString().padLeft(2, '0');
    return '${time!.day.toString().padLeft(2,'0')} '
        '${months[time!.month - 1]} ${time!.year}  $h:$m';
  }
}
