import 'dart:async';

/// Mock service to simulate API responses during UI development.
/// Replace with real API calls once backend is ready.
class MockFilterService {
  // Simulated delay to mimic network latency
  static const _delay = Duration(milliseconds: 800);

  // ── Auth ──────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_delay);

    // Dummy credentials for development
    if ((email == 'acme@filter.sa' || email == '0501234567') &&
        password == '123456') {
      return {
        'success': true,
        'token': 'dummy_jwt_token_acme_trading_co',
        'company_name': 'Acme Trading Co.',
        'email': email,
        'wallet_balance': 12450.0,
        'allowed_branches': ['Riyadh Main', 'Jeddah'],
      };
    }
    return {
      'success': false,
      'message': 'Invalid credentials. Please try again.',
    };
  }

  // ── Dashboard KPIs ───────────────────────────
  static Future<Map<String, dynamic>> getDashboardKpis() async {
    await Future.delayed(_delay);
    return {
      'total_bookings_year': 87,
      'this_month_spend': 45200.0,
      'total_spend': 128500.0,
      'wallet_balance': 12450.0,
      'savings_percent': 12,
    };
  }

  // ── Vehicles ──────────────────────────────────
  static Future<List<Map<String, dynamic>>> getVehicles() async {
    await Future.delayed(_delay);
    return [
      {
        'id': '1',
        'make': 'Toyota',
        'model': 'Camry',
        'plate': 'ABC-123',
        'year': 2022,
        'odometer': 45200,
        'color': 'White',
        'is_default': true,
      },
      {
        'id': '2',
        'make': 'BMW',
        'model': 'X5',
        'plate': 'XYZ-789',
        'year': 2021,
        'odometer': 32100,
        'color': 'Black',
        'is_default': false,
      },
      {
        'id': '3',
        'make': 'Hyundai',
        'model': 'Sonata',
        'plate': 'DEF-456',
        'year': 2023,
        'odometer': 18500,
        'color': 'Silver',
        'is_default': false,
      },
    ];
  }

  // ── Bookings ──────────────────────────────────
  static Future<List<Map<String, dynamic>>> getBookings() async {
    await Future.delayed(_delay);
    return [
      {
        'id': 'BK-9876',
        'date': '12 Feb 2026',
        'vehicle': 'ABC-123',
        'department': 'Oil Change',
        'status': 'Completed',
        'amount': 285.0,
        'invoice_id': 'INV-7845',
      },
      {
        'id': 'BK-9875',
        'date': '05 Feb 2026',
        'vehicle': 'XYZ-789',
        'department': 'Full Service',
        'status': 'In Progress',
        'amount': null,
        'invoice_id': null,
      },
      {
        'id': 'BK-9874',
        'date': '28 Jan 2026',
        'vehicle': 'DEF-456',
        'department': 'Tire Service',
        'status': 'Completed',
        'amount': 8200.0,
        'invoice_id': 'INV-7844',
      },
    ];
  }

  // ── Billing ───────────────────────────────────
  static Future<Map<String, dynamic>> getMonthlyBilling() async {
    await Future.delayed(_delay);
    return {
      'month': 'February 2026',
      'total_billed': 48750.0,
      'total_paid': 35200.0,
      'outstanding': 13550.0,
      'due_date': '15 March 2026',
      'wallet_used': 8450.0,
      'invoices': [
        {
          'id': 'INV-7845',
          'date': '12 Feb',
          'vehicle': 'ABC-123',
          'department': 'Oil Change',
          'amount': 285.0,
          'status': 'Paid',
        },
        {
          'id': 'INV-7846',
          'date': '20 Feb',
          'vehicle': 'XYZ-789',
          'department': 'Repair',
          'amount': 12450.0,
          'status': 'Pending',
        },
        {
          'id': 'INV-7847',
          'date': '25 Feb',
          'vehicle': 'DEF-456',
          'department': 'Tire Service',
          'amount': 8200.0,
          'status': 'Paid',
        },
      ],
    };
  }

  // ── Wallet ────────────────────────────────────
  static Future<Map<String, dynamic>> getWalletData() async {
    await Future.delayed(_delay);
    return {
      'balance': 12450.0,
      'total_topups': 45000.0,
      'total_spent': 32550.0,
      'transactions': [
        {
          'date': '12 Feb 2026',
          'description': 'Oil Change Invoice Payment',
          'amount': -285.0,
          'type': 'Debit',
          'balance_after': 12165.0,
        },
        {
          'date': '10 Feb 2026',
          'description': 'Wallet Top-up via Card',
          'amount': 10000.0,
          'type': 'Credit',
          'balance_after': 12450.0,
        },
        {
          'date': '05 Feb 2026',
          'description': 'Full Service Payment',
          'amount': -2450.0,
          'type': 'Debit',
          'balance_after': 2450.0,
        },
      ],
    };
  }
}
