import 'package:flutter/foundation.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';
import '../../models/billing_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/billing_repository.dart
//
// GET /corporate/billing/summary
// Response:
// {
//   "totalDue": 0,
//   "dueDate": "string",
//   "walletBalance": 0,
//   "paidAmount": 0,
//   "pendingAmount": 0,
//   "noOfPendingInvoices": 0,
//   "noOfPaidInvoices": 0,
//   "invoices": [{}]
// }
// ─────────────────────────────────────────────────────────────────────────────

class BillingRepository {
  BillingRepository._();

  static Future<ApiResponse<MonthlyBillingSummary>> fetchMonthlyBilling() async {
    const endpoint = ApiConstants.billingSummary;

    debugPrint('[BillingRepository] fetchMonthlyBilling → GET $endpoint');

    final response = await BaseApiService.get(endpoint);

    debugPrint('[BillingRepository] fetchMonthlyBilling ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[BillingRepository] fetchMonthlyBilling FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load billing data.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      debugPrint('[BillingRepository] fetchMonthlyBilling raw keys: '
          '${response.data!.keys.toList()}');

      final summary = _parseSummary(response.data!);

      debugPrint('[BillingRepository] fetchMonthlyBilling parsed: '
          'totalDue=${summary.totalDue} '
          'paidAmount=${summary.totalPaid} '
          'pendingAmount=${summary.totalPending} '
          'invoices=${summary.invoices.length}');

      return ApiResponse.success(summary);
    } catch (e, stack) {
      debugPrint('[BillingRepository] fetchMonthlyBilling PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  // ── Parser ────────────────────────────────────────────────────────────────

  static MonthlyBillingSummary _parseSummary(Map<String, dynamic> map) {
    final totalDue      = _toDouble(map['totalDue']);
    final paidAmount    = _toDouble(map['paidAmount']);
    final pendingAmount = _toDouble(map['pendingAmount']);
    final walletBalance = _toDouble(map['walletBalance']);
    final paidCount     = _toInt(map['noOfPaidInvoices']);
    final pendingCount  = _toInt(map['noOfPendingInvoices']);

    // Derive payment status
    BillingPaymentStatus status;
    if (pendingAmount <= 0 && totalDue > 0) {
      status = BillingPaymentStatus.paid;
    } else if (paidAmount > 0 && pendingAmount > 0) {
      status = BillingPaymentStatus.partial;
    } else {
      status = BillingPaymentStatus.pending;
    }

    // Parse dueDate
    DateTime dueDate;
    try {
      final raw = map['dueDate']?.toString() ?? '';
      dueDate = raw.isNotEmpty
          ? DateTime.parse(raw)
          : DateTime.now().add(const Duration(days: 15));
    } catch (_) {
      dueDate = DateTime.now().add(const Duration(days: 15));
    }

    // Parse invoices array
    final rawInvoices = map['invoices'];
    final invoices = <InvoiceModel>[];
    if (rawInvoices is List) {
      for (final item in rawInvoices) {
        if (item is Map<String, dynamic>) {
          try {
            invoices.add(_parseInvoice(item));
          } catch (e) {
            debugPrint('[BillingRepository] invoice parse skip: $e');
          }
        }
      }
    }

    // monthLabel — API doesn't return it, derive from current date
    final now = DateTime.now();
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final monthLabel = '${months[now.month - 1]} ${now.year}';

    return MonthlyBillingSummary(
      monthLabel:     monthLabel,
      totalDue:       totalDue,
      dueDate:        dueDate,
      walletBalance:  walletBalance,
      status:         status,
      invoices:       invoices,
      paidAmount:     paidAmount,
      pendingAmount:  pendingAmount,
      paidCount:      paidCount,
      pendingCount:   pendingCount,
    );
  }

  static InvoiceModel _parseInvoice(Map<String, dynamic> map) {
    final rawStatus = (map['status'] ?? '').toString().toLowerCase();
    InvoiceStatus status;
    switch (rawStatus) {
      case 'paid':    status = InvoiceStatus.paid;    break;
      case 'overdue': status = InvoiceStatus.overdue; break;
      case 'partial': status = InvoiceStatus.partial; break;
      default:        status = InvoiceStatus.pending;
    }

    final rawDate = map['created_at'] ?? map['date'] ?? map['invoice_date'];
    DateTime date;
    try {
      date = rawDate != null
          ? DateTime.parse(rawDate.toString())
          : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return InvoiceModel(
      invoiceNumber: (map['invoice_number'] ?? map['id'] ?? '').toString(),
      date:          date,
      vehiclePlate:  (map['vehicle_plate'] ?? map['plate_no'] ?? map['plateNo'] ?? '-').toString(),
      department:    (map['department'] ?? map['service'] ?? map['description'] ?? '-').toString(),
      amount:        _toDouble(map['amount']),
      status:        status,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int)  return v;
    if (v is num)  return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}