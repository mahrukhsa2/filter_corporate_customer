import 'package:flutter/foundation.dart';
import '../../models/branch_model.dart';
import '../../models/department_model.dart';
import '../../models/referral_model.dart';
import '../network/api_constants.dart';
import '../network/base_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/lookup_repository.dart
//
// Fetches static lookup data (branches, referrals, departments) from the API.
// ─────────────────────────────────────────────────────────────────────────────

class LookupRepository {
  LookupRepository._();

  // ── GET /corporate/branches ───────────────────────────────────────────────
  // PUBLIC endpoint - needed for registration
  // Response format: { "success": true, "branches": [...] }

  static Future<List<BranchModel>> fetchBranches() async {
    debugPrint('[LookupRepository] fetchBranches() START');

    final response = await BaseApiService.get(
      ApiConstants.branches,
      requiresAuth: false, // Public endpoint
    );

    debugPrint('[LookupRepository] fetchBranches() response: success=${response.success}, statusCode=${response.statusCode}');

    if (!response.success || response.data == null) {
      debugPrint('[LookupRepository] fetchBranches() FAILED: ${response.message}');
      return [];
    }

    try {
      debugPrint('[LookupRepository] fetchBranches() parsing data...');
      debugPrint('[LookupRepository] Response keys: ${response.data!.keys.toList()}');

      // Standard array format: { "success": true, "branches": [...] }
      final branchesList = response.data!['branches'] as List<dynamic>? ?? [];
      final branches = branchesList
          .map((item) => BranchModel.fromMap(item as Map<String, dynamic>))
          .toList();

      debugPrint('[LookupRepository] fetchBranches() SUCCESS - parsed ${branches.length} branches');
      for (final b in branches) {
        debugPrint('[LookupRepository]   → Branch: id=${b.id}, name=${b.name}');
      }

      return branches;
    } catch (e, stack) {
      debugPrint('[LookupRepository] fetchBranches() PARSE ERROR: $e');
      debugPrint('[LookupRepository] Stack: $stack');
      return [];
    }
  }

  // ── GET /corporate/departments?branchId=X ─────────────────────────────────
  // Authenticated endpoint - fetches departments for specific branch

  static Future<List<DepartmentModel>> fetchDepartmentsByBranch(
      String branchId,
      ) async {
    debugPrint('[LookupRepository] fetchDepartmentsByBranch() START - branchId: $branchId');

    final response = await BaseApiService.get(
      ApiConstants.departments,
      queryParams: {'branchId': branchId},
      requiresAuth: true,
    );

    debugPrint('[LookupRepository] fetchDepartmentsByBranch() response: success=${response.success}, statusCode=${response.statusCode}');

    if (!response.success || response.data == null) {
      debugPrint('[LookupRepository] fetchDepartmentsByBranch() FAILED: ${response.message}');
      return [];
    }

    try {
      // Departments use standard array format
      final deptsList = response.data!['departments'] as List<dynamic>? ?? [];

      final departments = deptsList
          .map((item) => DepartmentModel.fromApiMap(item as Map<String, dynamic>))
          .toList();

      debugPrint('[LookupRepository] fetchDepartmentsByBranch() SUCCESS - parsed ${departments.length} departments');
      for (final d in departments) {
        debugPrint('[LookupRepository]   → Department: id=${d.id}, name=${d.name}');
      }

      return departments;
    } catch (e, stack) {
      debugPrint('[LookupRepository] fetchDepartmentsByBranch() PARSE ERROR: $e');
      debugPrint('[LookupRepository] Stack: $stack');
      return [];
    }
  }

  // ── GET /corporate/referrals ──────────────────────────────────────────────
  // PUBLIC endpoint - needed for registration

  static Future<List<ReferralModel>> fetchReferrals() async {
    debugPrint('[LookupRepository] fetchReferrals() START');

    final response = await BaseApiService.get(
      ApiConstants.referrals,
      requiresAuth: false, // Public endpoint
    );

    debugPrint('[LookupRepository] fetchReferrals() response: success=${response.success}, statusCode=${response.statusCode}');

    if (!response.success || response.data == null) {
      debugPrint('[LookupRepository] fetchReferrals() FAILED: ${response.message}');
      return [];
    }

    try {
      // Referrals use standard array format
      final referralsList = response.data!['referrals'] as List<dynamic>? ?? [];

      final referrals = referralsList
          .map((item) => ReferralModel.fromMap(item as Map<String, dynamic>))
          .toList();

      debugPrint('[LookupRepository] fetchReferrals() SUCCESS - parsed ${referrals.length} referrals');
      for (final r in referrals) {
        debugPrint('[LookupRepository]   → Referral: id=${r.id}, name=${r.fullName}');
      }

      return referrals;
    } catch (e, stack) {
      debugPrint('[LookupRepository] fetchReferrals() PARSE ERROR: $e');
      debugPrint('[LookupRepository] Stack: $stack');
      return [];
    }
  }
}