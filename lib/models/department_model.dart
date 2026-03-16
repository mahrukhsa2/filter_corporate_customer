// ─────────────────────────────────────────────────────────────────────────────
// lib/models/department_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class DepartmentModel {
  final String id;
  final String name;
  final String icon;
  final String? workshopId; // branchId

  const DepartmentModel({
    required this.id,
    required this.name,
    this.icon = '🔧',
    this.workshopId,
  });

  /// Factory from hardcoded/cache data
  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      icon: map['icon']?.toString() ?? '🔧',
      workshopId: map['workshopId']?.toString(),
    );
  }

  /// Factory from API response (departments by branch)
  factory DepartmentModel.fromApiMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      icon: '🔧', // API doesn't return icon, use default
      workshopId: map['workshopId']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DepartmentModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}