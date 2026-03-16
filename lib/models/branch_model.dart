// ─────────────────────────────────────────────────────────────────────────────
// lib/models/branch_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class BranchModel {
  final String id;
  final String name;
  final String address;

  const BranchModel({
    required this.id,
    required this.name,
    required this.address,
  });

  /// Factory constructor from API response
  factory BranchModel.fromMap(Map<String, dynamic> map) {
    return BranchModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
    );
  }

  /// Display name for dropdowns (just the name, or name + city if you prefer)
  String get displayName => name;

  @override
  bool operator ==(Object other) =>
      other is BranchModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BranchModel(id: $id, name: $name, address: $address)';
}