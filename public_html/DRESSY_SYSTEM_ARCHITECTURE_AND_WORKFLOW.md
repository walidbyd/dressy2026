# DRESSY C2C MARKETPLACE — END-TO-END SYSTEM ARCHITECTURE & WORKFLOW GUIDE

> **Platform Version:** Dressy C2C Multi-Vendor Platform v1.5.6  
> **Backend:** Laravel 9 (PHP 8.2) + Inertia.js + Vue.js 3 + Tailwind CSS  
> **Mobile:** Flutter 3 (Android & iOS) with Provider State Management  
> **Database:** MySQL / MariaDB (`dressy_database.sql`)  
> **Target Production Domain:** `https://www.dressy-dz.com`  

---

## 1. System Architecture & Tech Stack Overview

### 1.1 Architectural Topology
Dressy is an Algerian Consumer-to-Consumer (C2C) pre-loved fashion marketplace. Every registered customer can buy and sell clothes directly. The platform manages escrow settlement through Cash-on-Delivery (COD) via Yalidine logistics, credits sellers' in-app wallets minus a platform commission, and disburses payouts to sellers via Algérie Poste (CCP) or BaridiMob.

```
       ┌────────────────────────────────────────────────────────┐
       │                Flutter Mobile App                      │
       │       (Buyers & Sellers: C2C Unified Experience)       │
       └──────────────────────────┬─────────────────────────────┘
                                  │ HTTPS REST API
                                  │ (Bearer Token / Sanctum + login_user_id)
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │                 Laravel 9 Backend                      │
       │  API Routes: routes/api_v1_0.php (/api/v1.0/...)       │
       │  Services: WalletService, OrderService, YalidineService│
       └──────────────┬──────────────────────────┬──────────────┘
                      │                          │
        Inertia.js    │                          │ SQL
        Props / Vue 3 │                          │ (PDO / Eloquent)
                      ▼                          ▼
       ┌────────────────────────┐      ┌────────────────────────┐
       │  Admin Control Panel   │      │   MySQL / MariaDB      │
       │ (/admin/escrow, etc.)  │      │   dressy_database.sql  │
       └────────────────────────┘      └────────────────────────┘
```

---

### 1.2 Mobile to Backend Communication
1. **Base URLs & Configuration**:
   - Defined in Flutter at `lib/config/ps_config.dart`:
     - `ps_core_url`: `https://www.dressy-dz.com` (or local `http://10.0.2.2/public_html` / `http://192.168.x.x` during development).
     - `ps_app_url`: `${ps_core_url}/api/v1.0/`.
     - `ps_bearer_token`: App-level shared bearer token passed in HTTP `Authorization` headers.
2. **User Identity & State**:
   - The user registers or logs in via `/api/v1.0/user/login` or `/api/v1.0/user/register`.
   - On successful login, the user's `user_id` and API token are persisted locally via `PsValueHolder` / `SharedPreferences`.
   - Every sensitive API request passes `login_user_id` as a query parameter or form-body attribute, validated on the backend by `checkAuthUserForApi` and user ownership policies.
3. **API Response Structure**:
   - Standard PSX response format:
     ```json
     {
       "status": "success",
       "code": 200,
       "message": "Operation successful",
       "data": { ... }
     }
     ```

---

### 1.3 Admin Panel (Inertia.js + Vue 3)
1. **Hybrid SSR / Client Architecture**:
   - Uses Laravel routing (`routes/web.php`) guarded by `['auth', 'checkDashboardPermission']`.
   - Controllers extend `App\Http\Controllers\PsController` and invoke the global `renderView('admin/...', $data)` helper.
   - Inertia passes server-side data directly as Vue component `props`. There are no client-side API token handshakes needed for the admin panel; session cookies and CSRF tokens handle web authentication.
2. **Page Resolution**:
   - Configured in `resources/js/app.js`:
     ```javascript
     resolve: (name) => {
         try {
             return withVite(import.meta.glob('./Pages/**/*.vue'), name)
         } catch (e) {
             return withVite(import.meta.glob('../../Modules/**/Resources/Pages/**/*.vue'), name)
         }
     }
     ```
   - All admin finance pages reside in both `resources/js/Pages/admin/` and are mirrored in `Modules/StoreFront/VendorPanel/Resources/Pages/admin/`.

---

### 1.4 Core Database Schema

| Table Name | Primary Purpose | Key Columns & Relations |
| :--- | :--- | :--- |
| `users` | User accounts (buyers, sellers, admins) | `id`, `name`, `email`, `user_phone`, `role_id` (1=SuperAdmin, 2=User). |
| `psx_vendors` | Vendor store associated with each user | `id`, `owner_user_id` &rarr; `users.id`, `name`, `status` (2=Approved). |
| `psx_items` | Clothing listings posted by sellers | `id`, `vendor_id` &rarr; `psx_vendors.id`, `category_id`, `unit_price`, `status`. |
| `psx_orders` | Orders placed by buyers | `id`, `user_id` (buyer) &rarr; `users.id`, `vendor_id` (seller store) &rarr; `psx_vendors.id`, `total_price`, `delivery_fee`, `order_status_id`, `order_code`, `yalidine_tracking`, `yalidine_parcel_id`, `yalidine_status`, `is_wallet_credited`, `wallet_credited_at`. |
| `psx_order_items` | Individual line items per order | `id`, `order_id` &rarr; `psx_orders.id`, `item_id` &rarr; `psx_items.id`, `quantity`, `unit_price`, `sub_total`. |
| `psx_shipping_and_billings` | Buyer delivery addresses | `id`, `order_id` &rarr; `psx_orders.id`, `shipping_first_name`, `shipping_last_name`, `shipping_phone`, `shipping_address`, `shipping_city`. |
| `psx_wallets` | Balance tracker per seller | `id`, `user_id` (unique) &rarr; `users.id`, `vendor_id`, `balance` (decimal 12,2), `currency_code` ('DZD'). |
| `psx_wallet_transactions` | Immutable audit ledger | `id`, `wallet_id` &rarr; `psx_wallets.id`, `user_id`, `type` (`credit`/`debit`), `amount`, `balance_after`, `reference_type` (`order`/`withdraw`/`manual`), `reference_id`, `note`, `added_user_id`. |
| `psx_withdraw_requests` | Seller cashout requests | `id`, `wallet_id`, `user_id`, `amount`, `status` (`pending`/`approved`/`rejected`), `note` (CCP/BaridiMob info), `admin_reference`, `admin_note`. |
| `psx_settings` | Dynamic platform finance config | `setting_env` = `'c2c_finance_setting'`, `setting` = JSON payload. |

---

## 2. End-to-End C2C Marketplace & COD Escrow Lifecycle

```
[Seller in Flutter]
       │
       ▼ (1) Registers ──► Backend auto-creates approved Vendor & COD config
       │
       ▼ (2) Lists clothing item with price & photos
       │
[Buyer in Flutter]
       │
       ▼ (3) Adds item to Cart ──► Checkout (COD Only) ──► Creates psx_orders (#Pending)
       │
[Seller in Flutter: "My Sales"]
       │
       ▼ (4) Accepts Order (Status = 2: Accepted)
       │
       ▼ (5) Dispatches Order (Status = 3: Delivering)
             └─► Yalidine API / Stub creates tracking (YAL-SIM-XXXXXX)
       │
[Logistics & Delivery]
       │
       ▼ (6) Package delivered ──► COD cash collected by Yalidine/Platform
       │
[Super Admin in Panel: /admin/escrow]
       │
       ▼ (7) Verifies cash collection ──► Clicks "Mark Paid & Credit"
             ├─ Row-level lock (lockForUpdate)
             ├─ Deducts dynamic Commission % (default 10%)
             ├─ Credits Net Payout to Seller's psx_wallets
             ├─ Writes immutable row to psx_wallet_transactions
             └─ Marks order is_wallet_credited = 1
       │
[Seller in Flutter: "My Wallet"]
       │
       ▼ (8) Balance reflects credited net payout
       │
       ▼ (9) Submits Withdrawal Request (Amount >= Min threshold, CCP/BaridiMob info)
       │
[Super Admin in Panel: /admin/withdrawals]
       │
       ▼ (10) Admin transfers funds via BaridiMob/CCP
             ├─ Approve: enters reference ID ──► atomically deducts wallet balance
             └─ Reject: enters reason ──► funds stay in seller's wallet
```

---

### Step 1 — User Registration & Auto-Vendor Onboarding
- **Problem Solved**: In standard multi-vendor systems, users must fill lengthy legal applications and wait days for admin approval before they can sell. In C2C Dressy, every buyer is also a seller.
- **Backend Implementation**:
  - Located in `Modules/Core/Http/Services/UserService.php` (`createApprovedVendorForUser`).
  - Triggered automatically when a user is created via the Eloquent `User::booted()` hook in `app/Models/User.php`:
    ```php
    static::created(function ($user) {
        \Modules\Core\Http\Services\UserService::createApprovedVendorForUser($user);
    });
    ```
  - Creates a row in `psx_vendors` with `owner_user_id = $user->id`, `status = 2` (Approved).
  - Automatically seeds Cash on Delivery (`payment00009`, status = 1) in `psx_vendor_payments`.
  - Seeds default order statuses in `psx_order_statuses` for that vendor.
  - Generates an empty wallet in `psx_wallets` with `balance = 0.00 DZD`.
- **Flutter UI**:
  - "Become a Vendor" application screens are hidden from the menu. New users can immediately click the **+ (Sell)** button.

---

### Step 2 — Item Listing & Checkout (COD Only)
1. **Item Submission**:
   - The seller opens `ItemEntryView` in Flutter, selects category (e.g., Robes, Vestes, Chaussures), condition, size, and price in DZD.
   - Endpoint called: `POST /api/v1.0/item/submit` or `POST /api/v1.0/item/add_item`.
   - The backend sets `vendor_id` to the seller's active vendor store.
2. **Checkout Payment Methods**:
   - When a buyer adds the item to the cart and proceeds to checkout, Flutter fetches payment settings via `POST /api/v1.0/vendor/info`.
   - Backend `VendorConfigInfoApiResource.php` is null-safe:
     ```php
     'vendor_cod_enabled' => ($codPayment && $codPayment->status == 1) ? "1" : "0",
     ```
   - In Flutter `checkout1_view.dart`, **only Cash on Delivery (COD)** is rendered. All credit card, Stripe, PayPal, Razorpay, and Paystack options are hidden.
3. **Order Creation**:
   - Buyer enters shipping information (name, Algerian phone number, Wilaya, commune, address).
   - Endpoints called:
     - `POST /api/v1.0/vendor/order_and_billing_info/submit` (stores delivery address in `psx_shipping_and_billings`).
     - `POST /api/v1.0/vendor/item_bought` (creates `psx_orders` and `psx_order_items`).
   - Order is created with `order_status_id = 1` (Pending) and `is_wallet_credited = 0`.

---

### Step 3 — Seller Order Management & Yalidine Dispatch
1. **"My Sales" Dashboard**:
   - In Flutter, sellers access the "My Sales" tab (`my_sales_view.dart`).
   - Endpoint called: `POST /api/v1.0/vendor/get_seller_orders?login_user_id={id}`.
   - Backed by `OrderService::getOrdersForSeller`:
     - Checks user's vendor ID (`Vendor::where('owner_user_id', $userId)->first()`).
     - Retrieves orders where `vendor_id = $vendor->id`.
2. **Accepting an Order**:
   - Seller taps **Accept**.
   - Endpoint called: `POST /api/v1.0/vendor/order/accept` with `order_id`.
   - Guarded by `OrderService::acceptOrderFromApi`:
     - Ensures the order belongs to the seller's vendor.
     - Ensures the current status is `1` (Pending).
     - Transitions status to `2` (Accepted / Confirmed).
3. **Dispatching with Yalidine Logistics**:
   - Seller prepares the parcel and taps **Dispatch**.
   - Endpoint called: `POST /api/v1.0/vendor/order/dispatch` with `order_id`.
   - Guarded by `OrderService::dispatchOrderFromApi`:
     - Ensures status is `2` (Accepted).
     - Calls `YalidineService::createParcel($order)`:
       - If **Stub Mode** (`yalidine_stub_mode = true`): Generates a simulated Algerian tracking number:
         ```php
         $tracking = 'YAL-SIM-' . strtoupper(Str::random(8));
         ```
       - If **Live Mode** (`yalidine_stub_mode = false`): Makes an HTTP POST to Yalidine API with `YALIDINE_API_TOKEN` and `YALIDINE_API_ID`.
     - Updates `psx_orders`:
       - `yalidine_tracking = $tracking`
       - `yalidine_parcel_id = $parcelId`
       - `yalidine_status = 'dispatched'`
       - `order_status_id = 3` (Delivering / Dispatched).
4. **Buyer Tracking**:
   - Buyer sees the live tracking badge in their order details view (`order_detail_view.dart`).

---

### Step 4 — COD Collection & Escrow Settlement (`Mark Paid`)
- **Problem Solved**: Because buyers pay cash on delivery to the Yalidine courier, the money arrives at Dressy's corporate bank/CCP account in settlement batches. The seller must not be credited until the platform has physically collected the cash. Once collected, Super Admin marks the order as paid.
- **Security Check**:
  - Non-admin users cannot call `markOrderPaid`. In `OrderService::markOrderPaidFromApi`:
    ```php
    if (User::find($userId)?->role_id !== Constants::superAdminRoleId) {
        return ['error' => 'Unauthorized. Super Admin access required.'];
    }
    ```
- **Admin Escrow Screen (`/admin/escrow`)**:
  - Super Admin opens `/admin/escrow`.
  - Table displays: Order Code, Buyer Name & Phone, Seller Store, Yalidine Tracking, Order Subtotal, Dynamic Commission Rate, Commission Amount, Net Seller Payout, and Escrow Status (`Unpaid (Escrow)` vs `Paid & Credited`).
- **Atomic Credit Execution (`WalletService::creditForOrder`)**:
  When Admin clicks **Mark Paid & Credit**:
  1. **Idempotency Guard**:
     ```php
     if ((int) $order->is_wallet_credited === 1 || !empty($order->wallet_credited_at)) {
         return ['already_credited' => true];
     }
     ```
  2. **Row Locking**:
     ```php
     $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->first();
     $lockedWallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();
     ```
  3. **Commission Deduction**:
     - Calculates item subtotal: `total_price - delivery_fee` (excluding shipping cost).
     - Reads platform commission from database settings:
       ```php
       $commissionPercent = self::getCommissionPercent(); // e.g. 10%
       $commissionAmount = round(($itemsSum * $commissionPercent) / 100, 2);
       $creditedAmount = round(max(0, $itemsSum - $commissionAmount), 2);
       ```
  4. **Balance & Ledger Update**:
     - Updates `psx_wallets.balance = balance + creditedAmount`.
     - Sets `psx_orders.is_wallet_credited = 1` and `psx_orders.wallet_credited_at = now()`.
     - Appends an audit entry to `psx_wallet_transactions`:
       - `type = 'credit'`
       - `amount = $creditedAmount`
       - `balance_after = $newBalance`
       - `reference_type = 'order'`
       - `reference_id = $order->id`
       - `note = "Order #{$order->order_code} settled (Item: {$itemsSum} DZD, Comm {$commissionPercent}%: -{$commissionAmount} DZD)"`
       - `added_user_id = Auth::id()`

---

### Step 5 — Seller Wallet & Immutable Ledger
- **Mobile Wallet View (`wallet_view.dart`)**:
  - Seller opens **My Wallet** from the drawer menu (`wallet_menu_widget.dart`).
  - Fetches balance via `POST /api/v1.0/vendor/wallet/balance`.
  - Fetches transaction history via `POST /api/v1.0/vendor/wallet/transactions`.
  - Screen displays:
    - Large balance card: `e.g. 12,500.00 DA`.
    - Chronological transaction feed:
      - **Green (+) badge**: Payout from settled orders or manual admin credits.
      - **Red (-) badge**: Approved withdrawals or manual deductions.
      - Shows date, order reference code, and ending balance.

---

### Step 6 — Payouts & Withdrawals (CCP / BaridiMob)
1. **Seller Request in Flutter**:
   - Seller taps **Request Withdrawal** in `wallet_view.dart`.
   - Modal prompts for:
     - Amount in DZD.
     - Note containing CCP account number, Clef, and Account Holder Name, or BaridiMob RIP (e.g., `00799999000123456789`).
   - Validations:
     - Amount must be positive.
     - Amount must not exceed current `wallet.balance`.
     - Amount must meet `min_withdraw_amount` (default `1,000 DZD`), enforced in `WalletService::submitWithdrawRequest`.
   - A row is inserted in `psx_withdraw_requests` with `status = 'pending'`.
   - **Important**: The seller's wallet balance is **not** deducted at submission time. This prevents money from disappearing if the request is canceled or rejected.
2. **Admin Review & Payout (`/admin/withdrawals`)**:
   - Super Admin opens `/admin/withdrawals`.
   - Filter tabs: `Pending`, `Approved`, `Rejected`, `All`.
   - **If Approved**:
     - Admin initiates the bank/postal transfer via BaridiMob or CCP office.
     - In the admin modal, Admin enters the transfer transaction ID (e.g. `BM-982341908`) into `admin_reference`.
     - Admin confirms. `AdminWithdrawalController::approve`:
       - Locks wallet row with `lockForUpdate()`.
       - Checks balance &ge; withdrawal amount.
       - Deducts amount from `psx_wallets.balance`.
       - Logs debit transaction in `psx_wallet_transactions` (`type = 'debit'`, `reference_type = 'withdraw'`).
       - Updates `psx_withdraw_requests` status to `'approved'` and saves `admin_reference`.
   - **If Rejected**:
     - Admin enters rejection reason (e.g., "Invalid CCP RIP number").
     - `AdminWithdrawalController::reject` sets status to `'rejected'` and logs reason in `admin_note`.
     - Zero balance is deducted; seller retains 100% of their funds.

---

## 3. Admin Panel Feature-by-Feature Breakdown

All admin finance routes are registered in `routes/web.php` inside the `prefix('admin')` group and protected by `['auth', 'checkDashboardPermission']`:

```php
Route::middleware(['auth', 'checkDashboardPermission'])->prefix('admin')->group(function () {
    // Escrow & COD Payouts
    Route::prefix('escrow')->controller(AdminEscrowController::class)->group(function () {
        Route::get('/', 'index')->name('admin.escrow.index');
        Route::post('/{id}/mark-paid', 'markPaid')->name('admin.escrow.markPaid');
    });

    // Seller Wallets & Manual Ledger Adjustment
    Route::prefix('wallets')->controller(AdminWalletController::class)->group(function () {
        Route::get('/', 'index')->name('admin.wallets.index');
        Route::post('/adjust', 'adjust')->name('admin.wallets.adjust');
        Route::get('/{userId}/history', 'history')->name('admin.wallets.history');
    });

    // Withdrawal Requests (CCP / BaridiMob)
    Route::prefix('withdrawals')->controller(AdminWithdrawalController::class)->group(function () {
        Route::get('/', 'index')->name('admin.withdrawals.index');
        Route::post('/{id}/approve', 'approve')->name('admin.withdrawals.approve');
        Route::post('/{id}/reject', 'reject')->name('admin.withdrawals.reject');
    });

    // Dynamic Commission & Finance Settings
    Route::prefix('commission')->controller(AdminCommissionController::class)->group(function () {
        Route::get('/', 'index')->name('admin.commission.index');
        Route::post('/', 'update')->name('admin.commission.update');
    });
});
```

### 3.1 COD Escrow / Mark Paid (`/admin/escrow`)
- **Controller**: `AdminEscrowController.php`
- **Vue Page**: `resources/js/Pages/admin/escrow/Index.vue`
- **Features**:
  - Live metric cards: Total Orders, Pending Settlement (DZD), Paid to Sellers (DZD), Platform Commission Earned (DZD).
  - Search by Order Code, Buyer Name, Buyer Phone, Seller Store, Yalidine Tracking.
  - Status filters: `All`, `Unpaid (Escrow)`, `Paid & Credited`.
  - Direct "Mark Paid & Credit" modal with full financial summary before confirmation.

### 3.2 Seller Wallets & "Change Wallet" (`/admin/wallets`)
- **Controller**: `AdminWalletController.php`
- **Vue Page**: `resources/js/Pages/admin/wallets/Index.vue`
- **Features**:
  - Metric cards: Total Held in Seller Wallets, Total Earned, Total Withdrawn.
  - Search sellers by name, email, phone, or store name.
  - **"Change Wallet" Action**: Allows Super Admin to perform an audited manual credit or debit. Requires an audited note explaining the adjustment (e.g. dispute resolution, manual cash deposit).
  - **Ledger History Link**: Leads directly to `/admin/wallets/{userId}/history`.

### 3.3 User Ledger History (`/admin/wallets/{userId}/history`)
- **Controller**: `AdminWalletController.php@history`
- **Vue Page**: `resources/js/Pages/admin/wallets/History.vue`
- **Features**:
  - Displays user profile, store name, current balance, and contact info.
  - Chronological table of all wallet transactions with type badges (+Credit / -Debit), amounts, running balance after, reference entity, note, and the Super Admin ID who executed the change.

### 3.4 Withdrawal Requests (`/admin/withdrawals`)
- **Controller**: `AdminWithdrawalController.php`
- **Vue Page**: `resources/js/Pages/admin/withdrawals/Index.vue`
- **Features**:
  - Tabbed filtering: `Pending`, `Approved`, `Rejected`, `All`.
  - Seller contact details & current available wallet balance.
  - Requested amount and seller-provided CCP / BaridiMob information.
  - **Approve Modal**: Prompts for BaridiMob/CCP transaction reference and internal notes. Atomically deducts funds upon submit.
  - **Reject Modal**: Prompts for required rejection reason. Preserves seller wallet balance.

### 3.5 Commission & Finance Settings (`/admin/commission`)
- **Controller**: `AdminCommissionController.php`
- **Vue Page**: `resources/js/Pages/admin/commission/Index.vue`
- **Features**:
  - **Platform Commission Rate (%)**: Configurable marketplace fee (default 10%). Dynamically overrides `.env` values.
  - **Minimum Withdrawal Threshold (DZD)**: Minimum balance required to request cashout (default 1,000 DZD).
  - **Yalidine Integration Mode**: Toggle between **Stub Simulation Mode** (generates realistic mock numbers) and **Live Production API Mode** (makes official calls to Yalidine API).
  - Stored in `psx_settings` under `setting_env = 'c2c_finance_setting'`.

---

## 4. Flutter Mobile App Feature-by-Feature Breakdown

### 4.1 Key Architecture & State Files
- **Configuration**: `lib/config/ps_config.dart`
- **API Client**: `lib/core/vendor/api/ps_api_service.dart`
- **Data Models**:
  - `lib/core/vendor/viewobject/wallet.dart`
  - `lib/core/vendor/viewobject/wallet_transaction.dart`
  - `lib/core/vendor/viewobject/order_history.dart`
  - `lib/core/vendor/viewobject/order_summary.dart`
- **Key Views**:
  - `lib/ui/vendor_ui/wallet/view/wallet_view.dart` (Seller wallet and withdrawal modal)
  - `lib/ui/vendor_ui/dashboard/components/drawer/widgets/wallet_menu_widget.dart` (Drawer entry)
  - `lib/ui/vendor_ui/order/view/my_sales_view.dart` (Seller order management)
  - `lib/ui/vendor_ui/order/view/order_detail_view.dart` (Order tracking & status)
  - `lib/ui/vendor_ui/checkout/view/checkout1_view.dart` (COD-only checkout flow)

### 4.2 Security Boundaries
- **No Mobile Mark Paid**: `mark_paid` endpoints are strictly reserved for Super Admins. The Flutter app has no UI, controllers, or service calls to mark orders as paid.
- **Ownership Verification**: All seller order operations verify that the authenticated user owns the vendor attached to the order.

---

## 5. Deployment & Configuration Checklist (Local vs. Hostinger Production)

When deploying updates between local development (XAMPP) and production Hostinger (`https://www.dressy-dz.com`), verify the following configuration points:

### 5.1 Laravel Backend (`public_html/.env`)
```ini
APP_NAME=Dressy
APP_ENV=production
APP_KEY=base64:...
APP_DEBUG=false
APP_URL=https://www.dressy-dz.com

# Database Connection (Hostinger MySQL)
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=u640778648_dressy
DB_USERNAME=u640778648_dressy_user
DB_PASSWORD=YourSecurePasswordHere

# Vite Front-End Asset URLs
VITE_BASE_DOMAIN=https://www.dressy-dz.com
VITE_APP_DIR=

# C2C Marketplace Commission (Fallback if DB setting is empty)
COMMISSION_PERCENT=10

# Yalidine Logistics API (Set Live Credentials on Production)
YALIDINE_API_URL=https://api.yalidine.app/v1/
YALIDINE_API_ID=your_yalidine_api_id
YALIDINE_API_TOKEN=your_yalidine_api_token
YALIDINE_STUB_MODE=false
```

### 5.2 Flutter Mobile App (`Mobile Source/dressy/lib/config/ps_config.dart`)
```dart
static const String ps_core_url = 'https://www.dressy-dz.com';
static const String ps_app_url = ps_core_url + '/api/v1.0/';
static const String ps_app_image_url = ps_core_url + '/public/storage/PSX_MPC/uploads/';
```

### 5.3 Production Deployment Steps
1. **Upload Files**: Upload the modified backend files to `public_html/`.
2. **Run Database Migrations**:
   - Access `https://www.dressy-dz.com/run-migration` while logged in as Super Admin, or via SSH:
     ```bash
     php artisan migrate --force
     ```
3. **Clear Caches**:
   ```bash
   php artisan optimize:clear
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```
4. **Vite Assets**:
   - Ensure the compiled assets in `public/build/` and `public/build/manifest.json` are uploaded.
5. **Verify Routes**:
   - Test navigating to:
     - `https://www.dressy-dz.com/admin/escrow`
     - `https://www.dressy-dz.com/admin/wallets`
     - `https://www.dressy-dz.com/admin/withdrawals`
     - `https://www.dressy-dz.com/admin/commission`
   - All 4 routes should return `200 OK` and render the complete sidebar navigation with the "Dressy Finance & Escrow" menu group.
