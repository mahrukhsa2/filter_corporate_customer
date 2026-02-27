# Filter Corporate Customer App

Flutter project for the **Corporate Customer Portal** of Filter — a vehicle workshop management platform.

---

## Project Structure

```
lib/
├── data/
│   ├── network/
│   │   ├── api_constants.dart       # All API endpoint strings
│   │   ├── api_response.dart        # Generic ApiResponse<T> wrapper
│   │   └── base_api_service.dart    # HTTP GET/POST with token injection
│   ├── repositories/
│   │   └── auth_repository.dart     # Auth calls (mock → real API swap)
│   └── models/
│       └── auth_response_model.dart
│
├── services/
│   ├── mock_filter_service.dart     # Dummy data for UI development
│   └── session_service.dart         # SharedPreferences wrapper
│
├── utils/
│   ├── app_colors.dart
│   ├── app_formatters.dart          # Arabic/Persian → English numeral converter
│   ├── app_text_styles.dart         # Manrope typography scale
│   ├── app_theme.dart               # Light + Dark Material3 themes
│   └── toast_service.dart           # Overlay toast notifications
│
├── l10n/
│   ├── app_en.arb                   # English strings
│   ├── app_ar.arb                   # Arabic strings
│   ├── app_localizations.dart       # Abstract base + delegate
│   ├── app_localizations_en.dart
│   └── app_localizations_ar.dart
│
├── views/
│   ├── Login/
│   │   ├── onboarding_view.dart     # 3-step onboarding (mobile + web)
│   │   ├── login_view.dart          # Login screen (mobile + web)
│   │   └── login_view_model.dart    # Provider ViewModel
│   └── Navbar/
│       ├── settings_view_model.dart # Locale + ThemeMode provider
│       ├── navbar_view_model.dart   # Bottom nav index provider
│       └── pos_shell.dart           # Placeholder shell
│
├── widgets/
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── custom_app_bar.dart
│   ├── custom_auth_header.dart
│   ├── menu_card.dart
│   └── widgets.dart                 # Barrel export
│
└── main.dart                        # Entry + MultiProvider + routing
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0

### Install dependencies
```bash
flutter pub get
```

### Run
```bash
# Mobile
flutter run

# Web
flutter run -d chrome
```

---

## Demo Credentials (Mock)
| Field    | Value              |
|----------|--------------------|
| Email    | `acme@filter.sa`   |
| Password | `123456`           |

---

## Key Decisions

| Topic | Decision |
|---|---|
| State Management | Provider (ChangeNotifier) |
| Font | Google Fonts — Manrope |
| Primary Color | `#FCC247` (Amber/Yellow) |
| Secondary Color | `#23262D` (Dark Charcoal) |
| Locale | EN / AR with full RTL support |
| Data Layer | `_useMock = true` — swap to `false` + uncomment real API calls |

---

## Switching to Real API

In `lib/data/repositories/auth_repository.dart`:
```dart
static const bool _useMock = false; // ← change this
```
Then uncomment the `BaseApiService.post(...)` call block.

Update `lib/data/network/api_constants.dart` with the real base URL.

---

## Next Screens (Planned)
- [ ] Registration Screen
- [ ] Dashboard / KPI Home
- [ ] Vehicles Management
- [ ] New Booking
- [ ] Price Quotation
- [ ] Wallet Screen
- [ ] Monthly Billing
- [ ] Reports Landing + All 8 sub-reports
