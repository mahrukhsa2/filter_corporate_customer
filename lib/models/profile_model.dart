// ─────────────────────────────────────────────────────────────────────────────
// lib/models/profile_model.dart
// ─────────────────────────────────────────────────────────────────────────────

/// A single branch from workshops[].branches[] in the profile API response.
class ProfileBranchModel {
  final String id;
  final String name;
  final String address;
  final String currencyCode;
  // API doesn't return an isActive flag per branch yet — defaulting to true.
  // Update fromMap() when backend adds it.
  final bool isActive;

  const ProfileBranchModel({
    required this.id,
    required this.name,
    this.address      = '',
    this.currencyCode = 'SAR',
    this.isActive     = true,
  });

  factory ProfileBranchModel.fromMap(Map<String, dynamic> map,
      {String fallbackCurrency = 'SAR'}) {
    return ProfileBranchModel(
      id:           map['id']?.toString()      ?? '',
      name:         map['name']?.toString()    ?? '',
      address:      map['address']?.toString() ?? '',
      currencyCode: fallbackCurrency,
      isActive:     true, // update when API adds status field
    );
  }
}

/// Full profile model used by ProfileScreen and ProfileViewModel.
///
/// API GET /corporate/profile response shape:
/// {
///   "id", "name", "email", "userType",
///   "workshops": [
///     { "id", "name", "currencyCode",
///       "branches": [ { "id", "name", "address" }, ... ] }
///   ],
///   "corporateAccount": {
///     "id", "companyName", "creditLimit", "dueBalance",
///     "billingAddress", "phoneNumber", "vatNumber", "walletBalance",
///     "referral": { ... }
///   }
/// }
class ProfileModel {
  // ── Read-only (from API) ───────────────────────────────────────────────────
  final String id;
  final String name;
  final String email;
  final String userType;
  final String companyName;
  final double creditLimit;
  final double dueBalance;
  final double walletBalance;
  final String vatNumber;

  /// Flattened list of all branches across all workshops.
  /// workshops[0].branches + workshops[1].branches + ...
  final List<ProfileBranchModel> branches;

  // ── Editable fields (in API + editable via PUT /corporate/profile) ─────────
  String billingAddress; // corporateAccount.billingAddress
  String mobile;         // corporateAccount.phoneNumber
  String contactPerson;  // not in API yet — editable locally until backend adds it

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.companyName,
    required this.creditLimit,
    required this.dueBalance,
    required this.walletBalance,
    required this.vatNumber,
    required this.branches,
    this.billingAddress = '',
    this.mobile         = '',
    this.contactPerson  = '',
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    final account = map['corporateAccount'] as Map<String, dynamic>? ?? {};

    // Flatten all branches across all workshops into a single list.
    // API: workshops[].branches[] — each workshop can have multiple branches.
    final workshopsRaw = map['workshops'];
    final branches = <ProfileBranchModel>[];
    if (workshopsRaw is List) {
      for (final workshop in workshopsRaw) {
        if (workshop is! Map<String, dynamic>) continue;
        final currency     = workshop['currencyCode']?.toString() ?? 'SAR';
        final branchesRaw  = workshop['branches'];
        if (branchesRaw is List) {
          for (final b in branchesRaw) {
            if (b is Map<String, dynamic>) {
              branches.add(ProfileBranchModel.fromMap(b,
                  fallbackCurrency: currency));
            }
          }
        }
      }
    }

    // billingAddress may be null in API → default to empty string
    final billingAddress =
        account['billingAddress']?.toString() ?? '';
    // API field is phoneNumber, we expose it as mobile
    final mobile =
        account['phoneNumber']?.toString() ?? '';
    final vatNumber =
        account['vatNumber']?.toString() ?? '';
    final walletBalance =
        (account['walletBalance'] as num?)?.toDouble() ?? 0.0;

    return ProfileModel(
      id:             map['id']?.toString()                        ?? '',
      name:           map['name']?.toString()                      ?? '',
      email:          map['email']?.toString()                     ?? '',
      userType:       map['userType']?.toString()                  ?? '',
      companyName:    account['companyName']?.toString()           ?? '',
      creditLimit:    (account['creditLimit'] as num?)?.toDouble() ?? 0.0,
      dueBalance:     (account['dueBalance']  as num?)?.toDouble() ?? 0.0,
      walletBalance:  walletBalance,
      vatNumber:      vatNumber,
      branches:       branches,
      billingAddress: billingAddress,
      mobile:         mobile,
      contactPerson:  '', // not in API yet
    );
  }
}