// ─────────────────────────────────────────────────────────────────────────────
// lib/models/registration_model.dart
// ─────────────────────────────────────────────────────────────────────────────

// ── Store selection model (for branch multi-select in registration UI) ────────

class StoreModel {
  final String id;
  final String name;
  final bool isSelected;

  const StoreModel({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  StoreModel copyWith({bool? isSelected}) {
    return StoreModel(
      id:         id,
      name:       name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// ── Registration API payload ──────────────────────────────────────────────────
//
// POST /auth/corporate/register body:
// {
//   "companyName":      "Mahrukh Corp",
//   "vatNumber":        "VAT-32323",
//   "contactPerson":    "Mahrukh Mirza",
//   "email":            "mahrukhsa28@gmail.com",
//   "password":         "password123",
//   "selectedStoreIds": ["5", "3"],
//   "referralId":       "1",
//   "mobile":           "+966500030000"
// }

class RegistrationPayload {
  final String        companyName;
  final String        vatNumber;
  final String        contactPerson;
  final String        email;
  final String        password;
  final List<String>  selectedStoreIds;
 // final String        mobile;
  final String?       referralId;   // ID from ReferralModel, optional

  const RegistrationPayload({
    required this.companyName,
    required this.vatNumber,
    required this.contactPerson,
    required this.email,
    required this.password,
    required this.selectedStoreIds,
 //   required this.mobile,
    this.referralId,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'companyName':      companyName,
      'vatNumber':        vatNumber,
      'contactPerson':    contactPerson,
      'email':            email,
      'password':         password,
      'selectedStoreIds': selectedStoreIds,
      //'mobile':           mobile,
    };
    // Only include referralId if provided — API treats it as optional
    if (referralId != null && referralId!.isNotEmpty) {
      map['referralId'] = referralId;
    }
    return map;
  }
}

// ── Registration API response ─────────────────────────────────────────────────

class RegistrationResult {
  final bool   success;
  final String message;

  const RegistrationResult({
    required this.success,
    required this.message,
  });

  factory RegistrationResult.fromMap(Map<String, dynamic> map) {
    return RegistrationResult(
      success: map['success'] as bool? ?? false,
      message: map['message']?.toString() ?? '',
    );
  }
}