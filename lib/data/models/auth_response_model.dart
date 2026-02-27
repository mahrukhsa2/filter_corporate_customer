// ─────────────────────────────────────────────────────────────────────────────
// lib/data/models/auth_response_model.dart
// Maps the real POST /auth/corporate/login response.
//
// Actual response shape:
// {
//   "success": true,
//   "token": "eyJ...",
//   "user": {
//     "id": "19", "name": "John Doe", "email": "...", "userType": "...",
//     "workshopId": "3",
//     "workshop": { "id","name","currencyCode","address","status" },
//     "corporateAccount": { "id","companyName","creditLimit","dueBalance","customerId" }
//   }
// }
// ─────────────────────────────────────────────────────────────────────────────

class AuthWorkshop {
  final String id;
  final String name;
  final String currencyCode;
  final String address;
  final String status;

  const AuthWorkshop({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.address,
    required this.status,
  });

  factory AuthWorkshop.fromMap(Map<String, dynamic> map) => AuthWorkshop(
        id:           map['id']?.toString()           ?? '',
        name:         map['name']?.toString()         ?? '',
        currencyCode: map['currencyCode']?.toString() ?? 'SAR',
        address:      map['address']?.toString()      ?? '',
        status:       map['status']?.toString()       ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id':           id,
        'name':         name,
        'currencyCode': currencyCode,
        'address':      address,
        'status':       status,
      };
}

class AuthCorporateAccount {
  final String id;
  final String companyName;
  final double creditLimit;
  final double dueBalance;
  final String customerId;

  const AuthCorporateAccount({
    required this.id,
    required this.companyName,
    required this.creditLimit,
    required this.dueBalance,
    required this.customerId,
  });

  factory AuthCorporateAccount.fromMap(Map<String, dynamic> map) =>
      AuthCorporateAccount(
        id:          map['id']?.toString()                    ?? '',
        companyName: map['companyName']?.toString()           ?? '',
        creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0.0,
        dueBalance:  (map['dueBalance']  as num?)?.toDouble() ?? 0.0,
        customerId:  map['customerId']?.toString()            ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id':          id,
        'companyName': companyName,
        'creditLimit': creditLimit,
        'dueBalance':  dueBalance,
        'customerId':  customerId,
      };
}

class AuthUser {
  final String              id;
  final String              name;
  final String              email;
  final String              userType;
  final String              workshopId;
  final AuthWorkshop        workshop;
  final AuthCorporateAccount corporateAccount;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.workshopId,
    required this.workshop,
    required this.corporateAccount,
  });

  factory AuthUser.fromMap(Map<String, dynamic> map) => AuthUser(
        id:         map['id']?.toString()         ?? '',
        name:       map['name']?.toString()       ?? '',
        email:      map['email']?.toString()      ?? '',
        userType:   map['userType']?.toString()   ?? '',
        workshopId: map['workshopId']?.toString() ?? '',
        workshop: AuthWorkshop.fromMap(
            (map['workshop'] as Map<String, dynamic>?) ?? {}),
        corporateAccount: AuthCorporateAccount.fromMap(
            (map['corporateAccount'] as Map<String, dynamic>?) ?? {}),
      );

  Map<String, dynamic> toMap() => {
        'id':               id,
        'name':             name,
        'email':            email,
        'userType':         userType,
        'workshopId':       workshopId,
        'workshop':         workshop.toMap(),
        'corporateAccount': corporateAccount.toMap(),
      };

  // Convenience getters — used across ViewModels
  String get companyName  => corporateAccount.companyName;
  double get creditLimit  => corporateAccount.creditLimit;
  double get dueBalance   => corporateAccount.dueBalance;
  String get workshopName => workshop.name;
  String get currencyCode => workshop.currencyCode;
}

/// Top-level login response
class AuthResponseModel {
  final bool     success;
  final String?  token;
  final AuthUser? user;
  final String?  message;

  const AuthResponseModel({
    required this.success,
    this.token,
    this.user,
    this.message,
  });

  factory AuthResponseModel.fromMap(Map<String, dynamic> map) =>
      AuthResponseModel(
        success: map['success'] as bool? ?? false,
        token:   map['token']?.toString(),
        user: map['user'] != null
            ? AuthUser.fromMap(map['user'] as Map<String, dynamic>)
            : null,
        message: map['message']?.toString(),
      );
}
