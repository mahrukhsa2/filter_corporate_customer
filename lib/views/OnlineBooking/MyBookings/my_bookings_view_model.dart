import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/orders_repository.dart';
import '../../../data/network/api_response.dart';
import '../../../models/booking_model.dart';
import '../../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/MyBookings/my_bookings_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum BookingHistoryLoadStatus { idle, loading, loadingMore, loaded, error }

class MyBookingsViewModel extends ChangeNotifier {

  // ── Load state ────────────────────────────────────────────────────────────
  BookingHistoryLoadStatus _loadStatus   = BookingHistoryLoadStatus.idle;
  List<BookingHistoryModel> _bookings    = [];
  String                    _errorMessage = '';
  ApiErrorType              _errorType    = ApiErrorType.none;

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int _pageSize = 10;
  int  _total   = 0;
  int  _offset  = 0;
  bool _hasMore = false;

  // ── Active filters ────────────────────────────────────────────────────────
  String?   _filterStatus;    // 'submitted' | 'approved' | 'in_progress' | 'completed' | 'cancelled'
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String?   _filterBranchId;

  // ── Getters ───────────────────────────────────────────────────────────────
  BookingHistoryLoadStatus  get loadStatus    => _loadStatus;
  List<BookingHistoryModel> get bookings      => _bookings;
  String                    get errorMessage  => _errorMessage;
  ApiErrorType              get errorType     => _errorType;
  bool get isLoading     => _loadStatus == BookingHistoryLoadStatus.loading;
  bool get isLoadingMore => _loadStatus == BookingHistoryLoadStatus.loadingMore;
  bool get hasError      => _loadStatus == BookingHistoryLoadStatus.error;
  bool get hasMore       => _hasMore;
  int  get total         => _total;

  // Filter getters
  String?   get filterStatus    => _filterStatus;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate   => _filterEndDate;
  String?   get filterBranchId  => _filterBranchId;
  bool get hasActiveFilters =>
      _filterStatus    != null ||
          _filterStartDate != null ||
          _filterEndDate   != null ||
          _filterBranchId  != null;

  MyBookingsViewModel() {
    _load(isRefresh: true);
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _load({
    bool          isRefresh = false,
    bool          isMore    = false,
    BuildContext? context,
  }) async {
    if (isRefresh) {
      _offset     = 0;
      _loadStatus = BookingHistoryLoadStatus.loading;
    } else if (isMore) {
      _loadStatus = BookingHistoryLoadStatus.loadingMore;
    } else {
      _loadStatus = BookingHistoryLoadStatus.loading;
    }
    notifyListeners();

    final response = await OrdersRepository.fetchOrders(
      status:    _filterStatus,
      startDate: _filterStartDate,
      endDate:   _filterEndDate,
      branchId:  _filterBranchId,
      limit:     _pageSize,
      offset:    _offset,
    );

    if (!response.success || response.data == null) {
      _errorMessage = response.message ?? 'Failed to load bookings.';
      _errorType    = response.errorType;
      _loadStatus   = BookingHistoryLoadStatus.error;

      debugPrint('[MyBookingsViewModel] FAILED '
          'errorType=${response.errorType} msg=$_errorMessage');

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: response.errorType,
          message:   response.message,
          onRetry: response.errorType == ApiErrorType.noInternet ||
              response.errorType == ApiErrorType.timeout
              ? () => _load(isRefresh: true, context: context)
              : null,
        );
      }
      notifyListeners();
      return;
    }

    final data = response.data!;

    if (isRefresh) {
      _bookings = data.orders;
    } else {
      _bookings.addAll(data.orders);
    }

    _total    = data.total;
    _hasMore  = (_offset + _pageSize) < _total;

    _errorMessage = '';
    _errorType    = ApiErrorType.none;
    _loadStatus   = BookingHistoryLoadStatus.loaded;

    debugPrint('[MyBookingsViewModel] loaded ${_bookings.length}/$_total '
        'hasMore=$_hasMore offset=$_offset');

    notifyListeners();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> refresh({BuildContext? context}) =>
      _load(isRefresh: true, context: context);

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !_hasMore) return;
    _offset += _pageSize;
    await _load(isMore: true);
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  Future<void> applyFilters({
    String?   status,
    DateTime? startDate,
    DateTime? endDate,
    String?   branchId,
    BuildContext? context,
  }) async {
    _filterStatus    = status;
    _filterStartDate = startDate;
    _filterEndDate   = endDate;
    _filterBranchId  = branchId;
    debugPrint('[MyBookingsViewModel] applyFilters: status=$status '
        'start=$startDate end=$endDate branchId=$branchId');
    await _load(isRefresh: true, context: context);
  }

  Future<void> clearFilters({BuildContext? context}) async {
    _filterStatus    = null;
    _filterStartDate = null;
    _filterEndDate   = null;
    _filterBranchId  = null;
    debugPrint('[MyBookingsViewModel] clearFilters');
    await _load(isRefresh: true, context: context);
  }
}