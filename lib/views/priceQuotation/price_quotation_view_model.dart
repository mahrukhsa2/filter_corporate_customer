import 'package:flutter/material.dart';
import '../../data/repositories/quotation_repository.dart';
import '../../data/network/api_response.dart';
import '../../models/product_quotation.dart';

class PriceQuotationViewModel extends ChangeNotifier {

  // ── Search state ──────────────────────────────────────────────────────────
  bool _isSearching = false;
  List<QuotationProduct> _searchResults = [];
  String _searchQuery = '';
  bool _showDropdown = false;

  // ── Line items (cart) ─────────────────────────────────────────────────────
  final List<QuotationLineItem> _lineItems = [];

  // ── Wallet ────────────────────────────────────────────────────────────────
  final double walletBalance = 12450;

  // ── Submit state ──────────────────────────────────────────────────────────
  QuotationSubmitStatus _submitStatus = QuotationSubmitStatus.idle;
  String _submitError = '';

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isSearching       => _isSearching;
  String get searchQuery     => _searchQuery;
  List<QuotationProduct> get searchResults => _searchResults;
  bool get showDropdown      => _showDropdown && _searchResults.isNotEmpty;
  List<QuotationLineItem> get lineItems => List.unmodifiable(_lineItems);
  bool get hasItems          => _lineItems.isNotEmpty;
  bool get isSubmitting      => _submitStatus == QuotationSubmitStatus.submitting;
  String get submitError     => _submitError;

  // ✅ DEPRECATED - kept for compatibility but always returns false
  // Use isSearching instead for inline loading indicator
  bool get isLoadingProducts => false;

  // Totals
  double get normalTotal  => _lineItems.fold(0, (s, i) => s + i.marketTotal);
  double get offeredTotal => _lineItems.fold(0, (s, i) => s + i.offeredTotal);
  double get totalSavings => normalTotal - offeredTotal;
  double get savingsPercent =>
      normalTotal > 0 ? (totalSavings / normalTotal) * 100 : 0;

  // Validation
  QuotationLineItem? get firstInvalidItem =>
      _lineItems.where((i) => !i.isPriceValid).firstOrNull;
  bool get allPricesValid => firstInvalidItem == null;

  // ── Search Products (API) ─────────────────────────────────────────────────

  Future<void> onSearchChanged(String query) async {
    _searchQuery = query;

    if (query.trim().isEmpty) {
      _searchResults = [];
      _showDropdown  = false;
      _isSearching   = false;
      notifyListeners();
      return;
    }

    // ✅ Show dropdown immediately with loading indicator
    _isSearching  = true;
    _showDropdown = true;
    notifyListeners();

    // ✅ Call API to search products
    final result = await QuotationRepository.searchProducts(
      query: query,
      //branchId: '1',
    );

    if (result.success && result.data != null) {
      // Filter out products already added to cart
      final addedIds = _lineItems.map((i) => i.product.id).toSet();
      _searchResults = result.data!
          .where((p) => !addedIds.contains(p.id))
          .toList();

      debugPrint('[PriceQuotationVM] Found ${_searchResults.length} products');
    } else {
      debugPrint('[PriceQuotationVM] Search failed: ${result.message}');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void hideDropdown() {
    _showDropdown = false;
    notifyListeners();
  }

  // ── Add Product to Cart ───────────────────────────────────────────────────

  void addProduct(QuotationProduct product) {
    _lineItems.add(QuotationLineItem(
      product: product,
      offeredPrice: product.corporatePrice,
    ));

    _searchQuery   = '';
    _searchResults = [];
    _showDropdown  = false;

    debugPrint('[PriceQuotationVM] Added: ${product.name}');
    notifyListeners();
  }

  // ── Remove Item from Cart ─────────────────────────────────────────────────

  void removeItem(int index) {
    _lineItems.removeAt(index);
    debugPrint('[PriceQuotationVM] Removed item at $index');
    notifyListeners();
  }

  // ── Update Quantity / Price ───────────────────────────────────────────────

  void setQuantity(int index, int qty) {
    if (qty < 1) return;
    _lineItems[index].quantity = qty;
    notifyListeners();
  }

  void setOfferedPrice(int index, double price) {
    _lineItems[index].offeredPrice = price;
    notifyListeners();
  }

  // ── Submit Quotation (API) ────────────────────────────────────────────────

  Future<QuotationSubmitResult?> submitQuotation() async {
    if (_lineItems.isEmpty) {
      debugPrint('[PriceQuotationVM] Cannot submit: no items');
      return null;
    }

    _submitStatus = QuotationSubmitStatus.submitting;
    _submitError = '';
    notifyListeners();

    debugPrint('[PriceQuotationVM] Submitting ${_lineItems.length} items');

    // ✅ Call API to submit quotation
    final result = await QuotationRepository.submitQuotation(
      items: _lineItems,
      notes: '',
      branchId: '1',
    );

    if (result.success && result.data != null) {
      debugPrint('[PriceQuotationVM] Submit SUCCESS: ${result.data!.reference}');

      _submitStatus = QuotationSubmitStatus.success;
      notifyListeners();

      return result.data;
    } else {
      debugPrint('[PriceQuotationVM] Submit FAILED: ${result.message}');

      _submitError = result.message ?? 'Failed to submit quotation';
      _submitStatus = QuotationSubmitStatus.error;
      notifyListeners();

      return null;
    }
  }

  void resetSubmitStatus() {
    _submitStatus = QuotationSubmitStatus.idle;
    _submitError = '';
    notifyListeners();
  }
}