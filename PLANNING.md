# LUNTI M-Commerce MVP Plan (School Submission Target: Nov 8)

## System Architecture
- **Mobile App (`lunti_app`)**: Flutter Android App
- **Web Admin (`admin_dashboard`)**: Flutter Web App
- **Backend**: Firebase Auth + Cloud Firestore (Direct SDK - NO Cloud Functions)

## Required Core Flow
1. **User Registration & Login**: Email/Password authentication on Mobile App.
2. **Product Browsing**: Fetch & display items from Firestore `products` collection with local asset image fallbacks (`assets/images/products/`).
3. **Cart & Checkout**: Add items to cart and save new order document in Firestore `orders` collection.
4. **Web Admin Dashboard**:
   - **Products Tab**: View products table + Add Product form saving directly to Firestore.
   - **Orders Tab**: View orders table + update status (Pending -> Approved -> Completed -> Cancelled).
5. **Real-time Order Sync**: Mobile App Order History screen uses `StreamBuilder` on Firestore to update status instantly.

## Execution Rules
- DO NOT create Node.js/TypeScript Cloud Functions, local emulators, or custom claims scripts.
- DO NOT split into unnecessary multi-phase architectural overhauls.
- Build UI directly connected to Firestore CRUD operations using Flutter packages (`firebase_core`, `firebase_auth`, `cloud_firestore`).