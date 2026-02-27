import 'package:flutter/material.dart';
import '../../../models/booking_service_report_model.dart';

enum BSLoadStatus { idle, loading, loaded }

class BookingServiceReportViewModel extends ChangeNotifier {
  BSLoadStatus _status = BSLoadStatus.idle;
  bool _isExporting    = false;

  List<BookingServiceItem> _all      = [];
  List<BookingServiceItem> _filtered = [];
  BookingServiceSummary?   _summary;
  BookingServiceFilters    _filters  = const BookingServiceFilters();

  bool get isLoading   => _status == BSLoadStatus.loading;
  bool get isExporting => _isExporting;
  List<BookingServiceItem> get items   => _filtered;
  BookingServiceSummary?   get summary => _summary;
  BookingServiceFilters    get filters => _filters;

  List<String> get branches => ['Branch A', 'Branch B', 'Branch C', 'Branch D'];

  BookingServiceReportViewModel() { _load(); }

  Future<void> _load() async {
    _status = BSLoadStatus.loading;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    _all = [
      BookingServiceItem(
        id: 'b01', bookingId: 'BK-9876',
        date: DateTime(2026, 2, 12), vehiclePlate: 'ABC-123',
        department: 'Oil Change', serviceType: ServiceType.oilChange,
        branch: 'Branch A', status: BookingStatus.completed, amount: 285,
      ),
      BookingServiceItem(
        id: 'b02', bookingId: 'BK-9875',
        date: DateTime(2026, 2, 5), vehiclePlate: 'XYZ-789',
        department: 'Full Service', serviceType: ServiceType.fullService,
        branch: 'Branch B', status: BookingStatus.inProgress,
      ),
      BookingServiceItem(
        id: 'b03', bookingId: 'BK-9874',
        date: DateTime(2026, 1, 28), vehiclePlate: 'DEF-456',
        department: 'Tire Service', serviceType: ServiceType.tireService,
        branch: 'Branch A', status: BookingStatus.completed, amount: 8200,
      ),
      BookingServiceItem(
        id: 'b04', bookingId: 'BK-9873',
        date: DateTime(2026, 1, 20), vehiclePlate: 'GHI-321',
        department: 'Car Wash', serviceType: ServiceType.carWash,
        branch: 'Branch C', status: BookingStatus.completed, amount: 120,
      ),
      BookingServiceItem(
        id: 'b05', bookingId: 'BK-9872',
        date: DateTime(2026, 1, 15), vehiclePlate: 'JKL-654',
        department: 'Inspection', serviceType: ServiceType.inspection,
        branch: 'Branch B', status: BookingStatus.cancelled,
      ),
      BookingServiceItem(
        id: 'b06', bookingId: 'BK-9871',
        date: DateTime(2026, 1, 10), vehiclePlate: 'MNO-987',
        department: 'Brake Service', serviceType: ServiceType.brakes,
        branch: 'Branch D', status: BookingStatus.completed, amount: 1400,
      ),
      BookingServiceItem(
        id: 'b07', bookingId: 'BK-9870',
        date: DateTime(2025, 12, 28), vehiclePlate: 'PQR-111',
        department: 'A/C Service', serviceType: ServiceType.ac,
        branch: 'Branch A', status: BookingStatus.completed, amount: 950,
      ),
      BookingServiceItem(
        id: 'b08', bookingId: 'BK-9869',
        date: DateTime(2025, 12, 20), vehiclePlate: 'STU-222',
        department: 'Oil Change', serviceType: ServiceType.oilChange,
        branch: 'Branch C', status: BookingStatus.pending,
      ),
      BookingServiceItem(
        id: 'b09', bookingId: 'BK-9868',
        date: DateTime(2025, 12, 15), vehiclePlate: 'VWX-333',
        department: 'Full Service', serviceType: ServiceType.fullService,
        branch: 'Branch B', status: BookingStatus.completed, amount: 3200,
      ),
      BookingServiceItem(
        id: 'b10', bookingId: 'BK-9867',
        date: DateTime(2025, 12, 8), vehiclePlate: 'YZA-444',
        department: 'Tire Service', serviceType: ServiceType.tireService,
        branch: 'Branch D', status: BookingStatus.cancelled,
      ),
      BookingServiceItem(
        id: 'b11', bookingId: 'BK-9866',
        date: DateTime(2025, 11, 30), vehiclePlate: 'BCD-555',
        department: 'Car Wash', serviceType: ServiceType.carWash,
        branch: 'Branch A', status: BookingStatus.completed, amount: 80,
      ),
      BookingServiceItem(
        id: 'b12', bookingId: 'BK-9865',
        date: DateTime(2025, 11, 22), vehiclePlate: 'EFG-666',
        department: 'Inspection', serviceType: ServiceType.inspection,
        branch: 'Branch C', status: BookingStatus.completed, amount: 450,
      ),
    ];

    _filtered = List.from(_all);
    _summary  = _buildSummary(_all);
    _status   = BSLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  void updateFilters(BookingServiceFilters f) {
    _filters = f;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _filters  = const BookingServiceFilters();
    _filtered = List.from(_all);
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _all.where((b) {
      if (_filters.fromDate != null && b.date.isBefore(_filters.fromDate!))
        return false;
      if (_filters.toDate != null &&
          b.date.isAfter(_filters.toDate!.add(const Duration(days: 1))))
        return false;
      if (_filters.status != null && b.status != _filters.status)
        return false;
      if (_filters.branch != null && b.branch != _filters.branch)
        return false;
      return true;
    }).toList();
  }

  BookingServiceSummary _buildSummary(List<BookingServiceItem> list) {
    int completed = 0, inProgress = 0, cancelled = 0, pending = 0;
    double spend = 0;
    for (final b in list) {
      switch (b.status) {
        case BookingStatus.completed:  completed++;  break;
        case BookingStatus.inProgress: inProgress++; break;
        case BookingStatus.cancelled:  cancelled++;  break;
        case BookingStatus.pending:    pending++;    break;
      }
      if (b.amount != null) spend += b.amount!;
    }
    return BookingServiceSummary(
      totalBookings: list.length,
      completed:  completed,
      inProgress: inProgress,
      cancelled:  cancelled,
      pending:    pending,
      totalSpend: spend,
    );
  }

  Future<void> exportReport() async {
    _isExporting = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _isExporting = false;
    notifyListeners();
  }
}
