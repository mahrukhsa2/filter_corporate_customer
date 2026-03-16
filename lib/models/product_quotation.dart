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
