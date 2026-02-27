import 'package:flutter/material.dart';

import '../../../data/repositories/orders_repository.dart';
import '../../../models/booking_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum BookingHistoryLoadStatus { idle, loading, loaded, error }

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsViewModel extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  BookingHistoryLoadStatus _loadStatus = BookingHistoryLoadStatus.idle;
  List<BookingHistoryModel> _bookings = [];
  String _errorMessage = '';

  // Pagination state
  int _total = 0;
  int _limit = 20;
  int _offset = 0;
  bool _hasMore = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  BookingHistoryLoadStatus get loadStatus => _loadStatus;
  List<BookingHistoryModel> get bookings => _bookings;
  String get errorMessage => _errorMessage;
  bool get isLoading => _loadStatus == BookingHistoryLoadStatus.loading;
  bool get hasMore => _hasMore;
  int get total => _total;

  MyBookingsViewModel() {
    _loadBookings();
  }

  // ── Load bookings from API ────────────────────────────────────────────────
  Future<void> _loadBookings({bool isRefresh = false}) async {
    _loadStatus = BookingHistoryLoadStatus.loading;
    notifyListeners();

    try {
      // If refreshing, reset offset
      if (isRefresh) {
        _offset = 0;
      }

      // Call the orders repository
      final response = await OrdersRepository.fetchOrders(
        limit: _limit,
        offset: _offset,
        // status: 'submitted', // Optional: filter by status
      );

      if (!response.success || response.data == null) {
        _loadStatus = BookingHistoryLoadStatus.error;
        _errorMessage = response.message ?? 'Failed to load bookings';
        notifyListeners();
        return;
      }

      final data = response.data!;

      // Update state
      if (isRefresh) {
        _bookings = data.orders;
      } else {
        _bookings.addAll(data.orders);
      }

      _total = data.total;
      _hasMore = (_offset + _limit) < _total;

      // Sort by date descending (newest first)
      _bookings.sort((a, b) => b.date.compareTo(a.date));

      _loadStatus = BookingHistoryLoadStatus.loaded;
      _errorMessage = '';
    } catch (e) {
      _loadStatus = BookingHistoryLoadStatus.error;
      _errorMessage = 'Failed to load bookings: ${e.toString()}';
    }

    notifyListeners();
  }

  // ── Refresh ───────────────────────────────────────────────────────────────
  Future<void> refresh() async {
    await _loadBookings(isRefresh: true);
  }

  // ── Load more (pagination) ────────────────────────────────────────────────
  Future<void> loadMore() async {
    if (_loadStatus == BookingHistoryLoadStatus.loading || !_hasMore) {
      return;
    }

    _offset += _limit;
    await _loadBookings();
  }

  // ── Filter bookings by status ─────────────────────────────────────────────
  List<BookingHistoryModel> getBookingsByStatus(String status) {
    return _bookings.where((b) => b.status == status).toList();
  }

  // ── Get booking by ID ─────────────────────────────────────────────────────
  BookingHistoryModel? getBookingById(String id) {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  // ── Load specific status ──────────────────────────────────────────────────
  Future<void> loadByStatus(String status) async {
    _loadStatus = BookingHistoryLoadStatus.loading;
    _offset = 0;
    notifyListeners();

    try {
      final response = await OrdersRepository.fetchOrders(
        status: status,
        limit: _limit,
        offset: _offset,
      );

      if (!response.success || response.data == null) {
        _loadStatus = BookingHistoryLoadStatus.error;
        _errorMessage = response.message ?? 'Failed to load bookings';
        notifyListeners();
        return;
      }

      final data = response.data!;
      _bookings = data.orders;
      _total = data.total;
      _hasMore = (_offset + _limit) < _total;

      // Sort by date descending
      _bookings.sort((a, b) => b.date.compareTo(a.date));

      _loadStatus = BookingHistoryLoadStatus.loaded;
      _errorMessage = '';
    } catch (e) {
      _loadStatus = BookingHistoryLoadStatus.error;
      _errorMessage = 'Failed to load bookings: ${e.toString()}';
    }

    notifyListeners();
  }
}