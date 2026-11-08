# LUNTI Admin Dashboard

A Firebase-powered admin dashboard for the LUNTI sustainable bamboo products e-commerce platform.

## Status

**PHASE 0 COMPLETE** — This is a skeleton Flutter Web project with authentication-ready routing. No Firebase connection yet.

## Architecture

```
admin_dashboard/lib/
├── main.dart              # App entry point
├── firebase_options.dart  # Firebase config placeholder
├── core/
│   └── router.dart        # GoRouter configuration
└── features/              # Screens (placeholder)
    ├── LoginPage
    ├── DashboardPage
    ├── ProductsPage
    ├── CategoriesPage
    ├── OrdersPage
    ├── OrderDetailPage
    └── CustomersPage
```

## Setup

1. **Configure Firebase for Web:**
   ```bash
   flutter pub add firebase_core
   flutter pub add firebase_auth
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   
   This generates the real `firebase_options.dart` with your project's credentials.

2. **Run the Dashboard:**
   ```bash
   flutter run -d chrome
   ```

## Project Isolation

This dashboard is **separate from the mobile app** (`lunti_app/`). The mobile app currently uses `MockAppState` for local prototype testing. The dashboard will connect to the same Firebase project when ready.

## Next Steps

- [ ] Phase 1: Firebase setup, auth, security rules
- [ ] Phase 1: Login page with role verification
- [ ] Phase 2: App shell and navigation

## Firebase Security

Admin status is enforced via Firebase Auth custom claims. See ADMIN_DASHBOARD_PLAN.md for the full security rules specification.