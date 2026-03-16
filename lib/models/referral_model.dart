// ─────────────────────────────────────────────────────────────────────────────
// lib/models/referral_model.dart
//
// API referral shape (from GET /corporate/referrals and inside profile):
// {
//   "id": "1",
//   "category": "01-Franchise",
//   "fullName": "John Doe",
//   "mobile": "+966500000000",
//   "email": "contact@referral.com"
// }
// ─────────────────────────────────────────────────────────────────────────────

class ReferralModel {
  final String id;
  final String fullName;
  final String category;
  final String mobile;
  final String email;

  const ReferralModel({
    required this.id,
    required this.fullName,
    this.category = '',
    this.mobile   = '',
    this.email    = '',
  });

  factory ReferralModel.fromMap(Map<String, dynamic> map) {
    return ReferralModel(
      id:       map['id']?.toString()       ?? '',
      fullName: map['fullName']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      mobile:   map['mobile']?.toString()   ?? '',
      email:    map['email']?.toString()    ?? '',
    );
  }

  /// Display name shown in referral dropdown
  String get displayName => fullName;

  @override
  bool operator ==(Object other) => other is ReferralModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}