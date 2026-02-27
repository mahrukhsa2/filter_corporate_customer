import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class QuotationProduct {
  final String id;
  final String name;
  final String unit;
  final double marketPrice;
  final double corporatePrice;
  final double minAllowedPrice; // dummy: corporatePrice * 0.85
  final double maxAllowedPrice; // dummy: marketPrice (cannot exceed market)

  const QuotationProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.marketPrice,
    required this.corporatePrice,
    required this.minAllowedPrice,
    required this.maxAllowedPrice,
  });
}

/// One row in the quotation table
class QuotationLineItem {
  final QuotationProduct product;
  int quantity;
  double offeredPrice;

  QuotationLineItem({
    required this.product,
    this.quantity = 1,
    required this.offeredPrice,
  });

  double get marketTotal  => product.marketPrice * quantity;
  double get offeredTotal => offeredPrice * quantity;

  bool get isPriceValid =>
      offeredPrice >= product.minAllowedPrice &&
      offeredPrice <= product.maxAllowedPrice;
}

enum QuotationSubmitStatus { idle, submitting, success, error }

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class PriceQuotationViewModel extends ChangeNotifier {
  // ── Catalogue ─────────────────────────────────────────────────────────────
  bool _isLoadingProducts = true;
  List<QuotationProduct> _allProducts = [];
  List<QuotationProduct> _searchResults = [];
  String _searchQuery = '';
  bool _showDropdown = false;

  // ── Line items (cart) ─────────────────────────────────────────────────────
  final List<QuotationLineItem> _lineItems = [];

  // ── Wallet ────────────────────────────────────────────────────────────────
  final double walletBalance = 12450;

  // ── Submit ────────────────────────────────────────────────────────────────
  QuotationSubmitStatus _submitStatus = QuotationSubmitStatus.idle;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoadingProducts => _isLoadingProducts;
  String get searchQuery     => _searchQuery;
  List<QuotationProduct> get searchResults => _searchResults;
  bool get showDropdown      => _showDropdown && _searchResults.isNotEmpty;
  List<QuotationLineItem> get lineItems => List.unmodifiable(_lineItems);
  bool get hasItems          => _lineItems.isNotEmpty;
  bool get isSubmitting      => _submitStatus == QuotationSubmitStatus.submitting;

  // Totals
  double get normalTotal  => _lineItems.fold(0, (s, i) => s + i.marketTotal);
  double get offeredTotal => _lineItems.fold(0, (s, i) => s + i.offeredTotal);
  double get totalSavings => normalTotal - offeredTotal;
  double get savingsPercent =>
      normalTotal > 0 ? (totalSavings / normalTotal) * 100 : 0;

  // First invalid item (for alert dialog)
  QuotationLineItem? get firstInvalidItem =>
      _lineItems.where((i) => !i.isPriceValid).firstOrNull;
  bool get allPricesValid => firstInvalidItem == null;

  PriceQuotationViewModel() {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _isLoadingProducts = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // Dummy catalogue – replace with real API
    _allProducts = const [
      QuotationProduct(id: 'p1',  name: '5W-30 Engine Oil',             unit: 'L',     marketPrice: 32,  corporatePrice: 29.50, minAllowedPrice: 25.08, maxAllowedPrice: 32),
      QuotationProduct(id: 'p2',  name: '10W-40 Engine Oil',            unit: 'L',     marketPrice: 28,  corporatePrice: 25.00, minAllowedPrice: 21.25, maxAllowedPrice: 28),
      QuotationProduct(id: 'p3',  name: 'Air Filter',                   unit: 'piece', marketPrice: 85,  corporatePrice: 72.00, minAllowedPrice: 61.20, maxAllowedPrice: 85),
      QuotationProduct(id: 'p4',  name: 'Oil Filter',                   unit: 'piece', marketPrice: 45,  corporatePrice: 38.50, minAllowedPrice: 32.73, maxAllowedPrice: 45),
      QuotationProduct(id: 'p5',  name: 'Brake Pads (Front)',           unit: 'set',   marketPrice: 220, corporatePrice: 185.00,minAllowedPrice: 157.25,maxAllowedPrice: 220),
      QuotationProduct(id: 'p6',  name: 'Brake Pads (Rear)',            unit: 'set',   marketPrice: 190, corporatePrice: 160.00,minAllowedPrice: 136.00,maxAllowedPrice: 190),
      QuotationProduct(id: 'p7',  name: 'Wiper Blades',                unit: 'pair',  marketPrice: 55,  corporatePrice: 44.00, minAllowedPrice: 37.40, maxAllowedPrice: 55),
      QuotationProduct(id: 'p8',  name: 'Coolant',                     unit: 'L',     marketPrice: 18,  corporatePrice: 14.50, minAllowedPrice: 12.33, maxAllowedPrice: 18),
      QuotationProduct(id: 'p9',  name: 'Transmission Fluid',          unit: 'L',     marketPrice: 40,  corporatePrice: 34.00, minAllowedPrice: 28.90, maxAllowedPrice: 40),
      QuotationProduct(id: 'p10', name: 'Spark Plugs',                 unit: 'piece', marketPrice: 35,  corporatePrice: 28.00, minAllowedPrice: 23.80, maxAllowedPrice: 35),
      QuotationProduct(id: 'p11', name: 'Mobil 1 Full Synthetic 5W-30',unit: 'liter', marketPrice: 75,  corporatePrice: 65.00, minAllowedPrice: 55.25, maxAllowedPrice: 75),
      QuotationProduct(id: 'p12', name: 'Bridgestone Tire 205/55R16',  unit: 'piece', marketPrice: 420, corporatePrice: 380.00,minAllowedPrice: 323.00,maxAllowedPrice: 420),
    ];

    _isLoadingProducts = false;
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────────────────────
  void onSearchChanged(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      _showDropdown  = false;
    } else {
      final addedIds = _lineItems.map((i) => i.product.id).toSet();
      _searchResults = _allProducts
          .where((p) =>
              !addedIds.contains(p.id) &&
              p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _showDropdown = true;
    }
    notifyListeners();
  }

  void hideDropdown() {
    _showDropdown = false;
    notifyListeners();
  }

  // ── Add from search ───────────────────────────────────────────────────────
  void addProduct(QuotationProduct product) {
    _lineItems.add(QuotationLineItem(
      product: product,
      offeredPrice: product.corporatePrice,
    ));
    _searchQuery   = '';
    _searchResults = [];
    _showDropdown  = false;
    notifyListeners();
  }

  // ── Remove row ────────────────────────────────────────────────────────────
  void removeItem(int index) {
    _lineItems.removeAt(index);
    notifyListeners();
  }

  // ── Update qty / price ────────────────────────────────────────────────────
  void setQuantity(int index, int qty) {
    if (qty < 1) return;
    _lineItems[index].quantity = qty;
    notifyListeners();
  }

  void setOfferedPrice(int index, double price) {
    _lineItems[index].offeredPrice = price;
    notifyListeners();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<bool> submitQuotation() async {
    if (_lineItems.isEmpty || !allPricesValid) return false;
    _submitStatus = QuotationSubmitStatus.submitting;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1100));
    // TODO: real API call
    _submitStatus = QuotationSubmitStatus.success;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _submitStatus = QuotationSubmitStatus.idle;
    notifyListeners();
    return true;
  }
}
