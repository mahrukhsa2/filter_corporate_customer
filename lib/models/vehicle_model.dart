// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class VehicleModel {
  final String id;
  String make;
  String model;
  String plateNumber;
  int odometer;
  int year;
  String color;
  bool isDefault;

  VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.plateNumber,
    required this.odometer,
    required this.year,
    required this.color,
    this.isDefault = false,
  });

  VehicleModel copyWith({
    String? make,
    String? model,
    String? plateNumber,
    int? odometer,
    int? year,
    String? color,
    bool? isDefault,
  }) {
    return VehicleModel(
      id: id,
      make: make ?? this.make,
      model: model ?? this.model,
      plateNumber: plateNumber ?? this.plateNumber,
      odometer: odometer ?? this.odometer,
      year: year ?? this.year,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
