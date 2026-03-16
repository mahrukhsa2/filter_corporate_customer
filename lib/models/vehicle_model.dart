// ─────────────────────────────────────────────────────────────────────────────
// lib/models/vehicle_model.dart
//
// API field mapping (GET /corporate/vehicles):
//   id        → id
//   plateNo   → plateNumber   (API uses plateNo, we normalise to plateNumber)
//   carNo     → carNo         (nullable, kept for future use)
//   make      → make
//   model     → model
//   year      → year
//   color     → color
//   odometer  → odometer
//   display   → displayLabel  (pre-formatted string from server)
//
// isDefault is NOT returned by the API. The first vehicle in the list
// is treated as default on load. User can change it locally.
// ─────────────────────────────────────────────────────────────────────────────

class VehicleModel {
  final String  id;
  String        make;
  String        model;
  String        plateNumber;  // normalised from API's "plateNo"
  String?       carNo;        // nullable — kept as-is from API
  int           odometer;
  int           year;
  String        color;
  bool          isDefault;
  String?       displayLabel; // pre-formatted "Toyota Camry 2022" from API

  VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.plateNumber,
    required this.odometer,
    required this.year,
    required this.color,
    this.carNo,
    this.isDefault   = false,
    this.displayLabel,
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id:           map['id']?.toString()       ?? '',
      make:         map['make']?.toString()     ?? '',
      model:        map['model']?.toString()    ?? '',
      plateNumber:  map['plateNo']?.toString()  ?? '',   // API key is plateNo
      carNo:        map['carNo']?.toString(),
      odometer:     (map['odometer'] as num?)?.toInt()  ?? 0,
      year:         (map['year']     as num?)?.toInt()  ?? 0,
      color:        map['color']?.toString()    ?? '',
      displayLabel: map['display']?.toString(),
    );
  }

  VehicleModel copyWith({
    String?  make,
    String?  model,
    String?  plateNumber,
    String?  carNo,
    int?     odometer,
    int?     year,
    String?  color,
    bool?    isDefault,
    String?  displayLabel,
  }) {
    return VehicleModel(
      id:           id,
      make:         make         ?? this.make,
      model:        model        ?? this.model,
      plateNumber:  plateNumber  ?? this.plateNumber,
      carNo:        carNo        ?? this.carNo,
      odometer:     odometer     ?? this.odometer,
      year:         year         ?? this.year,
      color:        color        ?? this.color,
      isDefault:    isDefault    ?? this.isDefault,
      displayLabel: displayLabel ?? this.displayLabel,
    );
  }
}