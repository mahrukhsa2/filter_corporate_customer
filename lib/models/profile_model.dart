// ── Data models ───────────────────────────────────────────────────────────────

class BranchModel {
  final String name;
  final bool isActive;

  const BranchModel({required this.name, required this.isActive});
}

class ProfileModel {
  final String companyName;
  final String vatNumber;
  String billingAddress;
  String contactPerson;
  String mobile;
  final double walletBalance;
  final List<BranchModel> branches;

  ProfileModel({
    required this.companyName,
    required this.vatNumber,
    required this.billingAddress,
    required this.contactPerson,
    required this.mobile,
    required this.walletBalance,
    required this.branches,
  });
}
