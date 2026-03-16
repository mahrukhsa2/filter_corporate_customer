import 'package:flutter/foundation.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';
import '../../models/wallet_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/wallet_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

class WalletRepository {
  WalletRepository._();

  // ── GET /corporate/wallet ─────────────────────────────────────────────────

  static Future<ApiResponse<WalletSummaryModel>> fetchWallet() async {
    debugPrint('[WalletRepository] fetchWallet → GET ${ApiConstants.wallet}');

    final response = await BaseApiService.get(ApiConstants.wallet);

    debugPrint('[WalletRepository] fetchWallet ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[WalletRepository] fetchWallet FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load wallet.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      debugPrint('[WalletRepository] fetchWallet raw keys: '
          '${response.data!.keys.toList()}');

      final summary = WalletSummaryModel.fromMap(response.data!);

      debugPrint('[WalletRepository] fetchWallet parsed: '
          'balance=${summary.balance} '
          'currency=${summary.currency} '
          'transactions=${summary.transactions.length} '
          'total_topups=${summary.totalTopups} '
          'total_spent=${summary.totalSpent}');

      if (summary.transactions.isNotEmpty) {
        debugPrint('[WalletRepository] fetchWallet first transaction: '
            'id=${summary.transactions.first.id} '
            'type=${summary.transactions.first.type} '
            'amount=${summary.transactions.first.amount} '
            'desc=${summary.transactions.first.description}');
      } else {
        debugPrint('[WalletRepository] fetchWallet: transactions list is empty');
      }

      return ApiResponse.success(summary);
    } catch (e, stack) {
      debugPrint('[WalletRepository] fetchWallet PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  // ── GET /corporate/wallet/summary ─────────────────────────────────────────
  // Response: { success, totalTopups, totalSpent, netMovement, currentBalance }

  static Future<ApiResponse<WalletSummaryStatsModel>> fetchSummary() async {
    debugPrint(
        '[WalletRepository] fetchSummary → GET ${ApiConstants.walletSummary}');

    final response = await BaseApiService.get(ApiConstants.walletSummary);

    debugPrint('[WalletRepository] fetchSummary ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[WalletRepository] fetchSummary FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load wallet summary.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      final d = response.data!;
      final stats = WalletSummaryStatsModel(
        currentBalance: (d['currentBalance'] as num?)?.toDouble() ?? 0.0,
        totalTopups:    (d['totalTopups']    as num?)?.toDouble() ?? 0.0,
        totalSpent:     (d['totalSpent']     as num?)?.toDouble() ?? 0.0,
        netMovement:    (d['netMovement']    as num?)?.toDouble() ?? 0.0,
      );

      debugPrint('[WalletRepository] fetchSummary parsed: '
          'balance=${stats.currentBalance} '
          'topups=${stats.totalTopups} '
          'spent=${stats.totalSpent} '
          'net=${stats.netMovement}');

      return ApiResponse.success(stats);
    } catch (e, stack) {
      debugPrint('[WalletRepository] fetchSummary PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  // ── POST /corporate/wallet/topup ─────────────────────────────────────────
  // Body:  { "amount": 5000, "paymentMethod": "pm1" }
  // 201:   { "success": true, "newBalance": 5000 }

  static Future<ApiResponse<double>> topUp({
    required double amount,
    required String paymentMethodId,
  }) async {
    final body = {
      'amount':        amount,
      'paymentMethod': paymentMethodId,
    };

    debugPrint('[WalletRepository] topUp → POST ${ApiConstants.walletTopup}');
    debugPrint('[WalletRepository] topUp body: $body');

    final response = await BaseApiService.post(ApiConstants.walletTopup, body);

    debugPrint('[WalletRepository] topUp ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[WalletRepository] topUp FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Top-up failed. Please try again.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      debugPrint('[WalletRepository] topUp raw response: ${response.data}');
      final newBalance = (response.data!['newBalance'] as num?)?.toDouble();
      if (newBalance == null) {
        debugPrint('[WalletRepository] topUp WARNING: newBalance missing');
        return ApiResponse.error(
          'Unexpected response from server.',
          errorType: ApiErrorType.unknown,
        );
      }
      debugPrint('[WalletRepository] topUp SUCCESS: newBalance=$newBalance');
      return ApiResponse.success(newBalance);
    } catch (e, stack) {
      debugPrint('[WalletRepository] topUp PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }
}