// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class QuotationProduct {
  final String id;
  final String name;
  final String unit;
  final double marketPrice;
  final double corporatePrice;

  const QuotationProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.marketPrice,
    required this.corporatePrice,
  });
}
