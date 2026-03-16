import 'package:flutter/foundation.dart';
import '../network/api_constants.dart';
import '../network/base_api_service.dart';
import '../network/api_response.dart';
import '../../models/profile_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/profile_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

class ProfileRepository {
  ProfileRepository._();

  // ── GET /corporate/profile ────────────────────────────────────────────────

  static Future<ApiResponse<ProfileModel>> fetchProfile() async {
    debugPrint('[ProfileRepository] fetchProfile → GET ${ApiConstants.profile}');

    final response = await BaseApiService.get(ApiConstants.profile);

    debugPrint('[ProfileRepository] fetchProfile ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[ProfileRepository] fetchProfile FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load profile.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      debugPrint('[ProfileRepository] fetchProfile raw keys: '
          '${response.data!.keys.toList()}');

      final profile = ProfileModel.fromMap(response.data!);

      debugPrint('[ProfileRepository] fetchProfile parsed: '
          'id=${profile.id} '
          'name=${profile.name} '
          'company=${profile.companyName} '
          'branches=${profile.branches.length} '
          'billingAddress=${profile.billingAddress} '
          'mobile=${profile.mobile} '
          'vatNumber=${profile.vatNumber} '
          'walletBalance=${profile.walletBalance}');

      for (final b in profile.branches) {
        debugPrint('[ProfileRepository]   → branch id=${b.id} '
            'name=${b.name} address=${b.address}');
      }

      return ApiResponse.success(profile);
    } catch (e, stack) {
      debugPrint('[ProfileRepository] fetchProfile PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  // ── PUT /corporate/profile ────────────────────────────────────────────────
  // 200: { "success": true, "message": "Profile updated successfully" }
  //
  // Body sends only the fields the user can edit.
  // contactPerson is not in the API yet — included anyway so it's ready
  // when the backend adds it. Server will silently ignore unknown fields.

  static Future<ApiResponse<bool>> updateProfile({
    required String billingAddress,
    required String contactPerson,
    required String mobile,
  }) async {
    final body = <String, dynamic>{
      'billingAddress': billingAddress,
      'phoneNumber':    mobile,         // API field name is phoneNumber
      'contactPerson':  contactPerson,  // not in API yet — ignored by server
    };

    debugPrint('[ProfileRepository] updateProfile → PUT ${ApiConstants.profile}');
    debugPrint('[ProfileRepository] updateProfile body: $body');

    final response = await BaseApiService.put(ApiConstants.profile, body);

    debugPrint('[ProfileRepository] updateProfile ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success) {
      debugPrint('[ProfileRepository] updateProfile FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to update profile.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    final message = response.data?['message']?.toString() ?? 'Profile updated.';
    debugPrint('[ProfileRepository] updateProfile SUCCESS: $message');
    return ApiResponse.success(true);
  }
}