# 🚀 MEZZO VERSION 2.0 — ARCHITECTURAL BLUEPRINT & ROADMAP
> **Document Purpose:** Complete, exhaustive product and engineering specification for Mezzo 2.0 (Campus Dining + Tiffin Delivery Network).  
> **Target Release:** Version 2.0 Major Update  
> **Author & Architect:** Antigravity AI & Mohit Agnihotri  
> **Status:** APPROVED FOR V2 IMPLEMENTATION  

---

## 📌 TABLE OF CONTENTS
1. [Executive Summary & Core Vision](#1-executive-summary--core-vision)
2. [What's New in Version 2.0 (Feature Modules)](#2-whats-new-in-version-20-feature-modules)
3. [All Roles & End-to-End User Workflows](#3-all-roles--end-to-end-user-workflows)
4. [Role-Based Access Control (RBAC) & Security](#4-role-based-access-control-rbac--security)
5. [The 24-Hour Master Operational Lifecycle](#5-the-24-hour-master-operational-lifecycle)
6. [Backward Compatibility & Migration Guide](#6-backward-compatibility--migration-guide)
   - *How Existing Owners & Students Update to V2*
   - *How New Users Experience V2*
   - *Database Schema Deltas & Safe Fallbacks*
7. [Step-by-Step Implementation Checklist for V2](#7-step-by-step-implementation-checklist-for-v2)

---

## 1. EXECUTIVE SUMMARY & CORE VISION

### 🎯 The Evolution:
* **Version 1.0 (Current):** A specialized SaaS tool for **Dine-in Messes** (Headcount tracking, advance monthly billing, meal skips carry-forward, QR discovery standee, and branded PDF invoices).
* **Version 2.0 (Next):** Expanding into a **Unified Campus Dining & Hyperlocal Tiffin Network**. Connecting independent home-tiffin providers, cloud kitchens, and hybrid mess operators with zero delivery liability on the platform.

### 🛡️ Core Business Principles for V2:
1. **Zero Platform Delivery Liability:** The app provides software, dispatch sheets, and route management. Food delivery is fulfilled directly by the tiffin provider's existing delivery staff.
2. **Zero Payment Gateway Friction:** No 2% gateway cuts, no wallet compliance, no chargebacks. Pay-per-meal diners pay Cash/UPI directly upon delivery. Monthly subscribers settle advance fees with the owner as usual.
3. **100% Google Sign-In Retention:** Zero SMS OTP charges, zero TRAI/DLT legal overhead. 1-click free Google auth across all personas.

---

## 2. WHAT'S NEW IN VERSION 2.0 (FEATURE MODULES)

### Module A: Multi-Business Type Support
During registration or in settings, business owners choose from 3 business modes:
1. `🍽️ Dine-in Mess`: Traditional dining hall where students walk in and eat.
2. `🛵 Tiffin Service`: Kitchens delivering packed tiffin boxes to student rooms, PGs, and flats.
3. `🌟 Both (Hybrid)`: Operators running both a physical mess hall and a tiffin delivery route.

### Module B: The 2-Bucket Diner Model (Members vs. Pay-Per-Meal)
To avoid voucher abuse while supporting casual diners:
* **Bucket 1: Monthly Subscriber (`[🟢 MEMBER]`)**
  - Paid full month advance fee (e.g. ₹2,600/mo = ~₹70/meal).
  - Enjoys full meal skip rights with next-month bill roll-over deductions (Option 1 logic).
  - Delivery boy collects ₹0 at doorstep.
* **Bucket 2: Pay-Per-Meal / Casual Diner (`[🟠 PAY-PER-MEAL]`)**
  - For students testing the food (Trial) or ordering ad-hoc during exam weeks.
  - Charged the owner's fixed **Flat Single-Meal Rate** (e.g. ₹85/meal).
  - Delivery boy collects flat ₹85 (Cash/UPI) upon delivery.
  - After delivery, student gets an in-app prompt: `[Switch to Monthly Plan]` or `[Skip / Not Now]`.

### Module C: Interactive Dispatch Sheet & Route Manifest
Tiffin owners get an automated, real-time packing list:
* Kitchen view: Exact count of tiffins to pack (Members minus today's skips plus today's pay-per-meal orders).
* Building-wise route grouping: *Sunrise PG (4 tiffins), Shivaji Flats (3 tiffins)...*
* Skipped meals marked with a prominent red badge: `[❌ SKIPPED - DO NOT DELIVER]`.

### Module D: Dedicated Delivery Partner Portal (Role-Based Sub-Account)
* Owners can add staff members from their dashboard (`+ Add Delivery Member`).
* Generates a **15-Minute Expiring 6-Digit PIN** (e.g. `582 914`) for maximum security.
* Delivery boys log in with Google, enter this PIN once, and unlock a distraction-free **Delivery Partner Screen**.
* Features:
  - Building-wise delivery checklist with `[Mark Delivered]` toggle.
  - Student room number, floor, and delivery notes ("Leave at guard desk").
  - Clear collection indicators: `[Collect ₹85 Cash/UPI]` vs `[Pre-Paid ₹0]`.
  - 1-tap phone dialer to call student without saving numbers.
  - End-of-shift Cash Reconciliation: Auto-tallies total cash collected (e.g. `Total to hand over: ₹170`).

---

## 3. ALL ROLES & END-TO-END USER WORKFLOWS

```
                                  MEZZO 2.0 LAUNCH
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
         [ 👤 DINER / STUDENT ]                         [ 🏢 BUSINESS OWNER ]
                 │                                               │
      ┌──────────┴──────────┐                      ┌─────────────┼─────────────┐
      ▼                     ▼                      ▼             ▼             ▼
[ 🍽️ Mess Diner ]    [ 🛵 Tiffin Diner ]      [ Pure Mess ] [ Pure Tiffin ] [ Both / Hybrid ]
```

### 👤 Workflow 1: The Diner / Student
1. **Discover Screen:**
   - Seamless top toggle: `[ 🍽️ Dine-in Messes ]` vs `[ 🛵 Tiffin Services ]`.
   - In Tiffin view: Filters by distance & delivery radius. Shows sample menu, daily rate, and monthly fee.
2. **Ordering:**
   - If not a member: Taps "Order Today's Tiffin" -> Enters PG Name, Room/Flat, Delivery Note -> Confirms order (`Cash on Delivery`).
   - If monthly member: Tiffin automatically dispatched daily unless skipped before the 9:30 AM cutoff.
3. **Delivery & Feedback:**
   - Push notification when marked delivered: *"Your Lunch Tiffin has reached Sunrise PG Room 204!"*
   - Casual diners receive conversion card: `[🚀 Switch to Monthly Plan]` or `[⏭️ Skip / Not Now]`.

---

### 🏢 Workflow 2: Pure Mess Owner (Dine-in Only)
* Unaffected by tiffin features.
* Dashboard shows: `Live Hall Headcount`, `Menu Planner`, `QR Standee Sheet`, and `Advance Monthly Billing`.

---

### 🛵 Workflow 3: Pure Tiffin Center Owner
1. **08:00 AM:** Publishes daily menu. Diners receive push broadcast.
2. **09:30 AM (Hard Cutoff):** Skip cancellations lock. Dashboard freezes final cooking count:
   - `42 Monthly Members (6 Skipped)` + `5 Pay-Per-Meal Orders` = **Total 47 Boxes to Pack**.
3. **11:00 AM:** Delivery boy opens app -> views today's route.
4. **12:30 PM - 02:30 PM:** Delivery boy marks boxes as delivered and collects cash from pay-per-meal diners.
5. **03:00 PM:** Delivery boy hands over cash matched exactly with the app's total.

---

### 👑 Workflow 4: Hybrid Owner (Both Mess & Tiffin)
* Master dual dashboard with split counters:
  - `Total Headcount: 105 Meals`
  - `🍽️ Mess Dine-in: 58 Persons (Counter dining)`
  - `🛵 Tiffin Delivery: 47 Boxes (Packed by 11:30 AM for route)`
* Student management roster has quick filters: `[All] | [Mess Diners] | [Tiffin Diners]`.

---

### 🚴 Workflow 5: Delivery Partner / Staff Member
* Opens Mezzo -> Logs in with 1-click Google Sign-in.
* Enters owner's 15-minute expiring invite PIN (first-time only).
* Sees only their assigned delivery route for the active meal slot (Lunch / Dinner).
* Taps `[Mark Delivered]` as they go. Cash collected auto-sums at the bottom.

---

## 4. ROLE-BASED ACCESS CONTROL (RBAC) & SECURITY

To guarantee zero data leaks and privacy:

```
┌──────────────────────────────────────┬─────────┬─────────┬─────────┐
│ Feature / Capability                 │ Diner   │ Staff   │ Owner   │
├──────────────────────────────────────┼─────────┼─────────┼─────────┤
│ View Public Menus & Prices           │   YES   │   YES   │   YES   │
│ Mark Personal Skip (Before Cutoff)   │   YES   │   NO    │   YES   │
│ View Delivery Route & Room Numbers   │   NO    │   YES   │   YES   │
│ Mark Meal as Delivered               │   NO    │   YES   │   YES   │
│ Collect Cash & Confirm Receipt       │   NO    │   YES   │   YES   │
│ View Business Earnings & Profit      │ BLOCKED │ BLOCKED │   YES   │
│ Change Meal Pricing / Plan Settings  │ BLOCKED │ BLOCKED │   YES   │
│ Add or Deactivate Delivery Staff     │ BLOCKED │ BLOCKED │   YES   │
│ Download Monthly Student PDF Invoices│ OWN ONLY│ BLOCKED │ ALL     │
└──────────────────────────────────────┴─────────┴─────────┴─────────┘
```

---

## 5. THE 24-HOUR MASTER OPERATIONAL LIFECYCLE

```
08:00 AM ──> Daily Menu Published by Owner
             └─ Push alert to all students ("Paneer Butter Masala today!")
             
09:30 AM ──> 🔒 HARD CUTOFF HIT
             ├─ Students can no longer cancel lunch (Food waste prevented!)
             ├─ Owner Dashboard freezes: "Pack 47 Tiffins"
             └─ Delivery Partner app generates today's Route Sheet
             
11:30 AM ──> 🍳 Cooking & Packing Complete
             └─ Delivery boy loads 47 packed boxes
             
12:30 PM ──> 🛵 PEAK DISPATCH & DINE-IN
             ├─ Tiffin: Delivered to rooms, cash collected from ad-hoc diners
             └─ Mess: Students walk in, scan QR code standee
             
02:30 PM ──> 🏁 LUNCH CYCLE CLOSES
             ├─ Delivery boy returns, cash reconciled in 10 seconds
             └─ Ad-hoc diners get rating prompt: "Rate Meal ⭐ [Switch to Monthly]"
             
05:00 PM ──> 🌙 DINNER CYCLE BEGINS (Repeats exact same flow)
```

---

## 6. BACKWARD COMPATIBILITY & MIGRATION GUIDE

### A. How Existing Users Experience the V2 Update
1. **Existing Mess Owners (100% Zero Friction):**
   - Play Store updates the app to V2.0.
   - When the owner logs in, the backend reads their existing `MessModel`.
   - Field `serviceType` safely defaults to `'dine_in'`.
   - The owner sees their exact same dashboard! Nothing changes or breaks.
   - An optional banner in Settings appears:  
     > *"New: Want to deliver tiffins to nearby hostels? Enable Tiffin Delivery with 1 tap."*
2. **Existing Students / Diners (100% Zero Friction):**
   - The app updates. Existing subscriptions, attendance records, and monthly bills remain intact.
   - In the Discover page, they now see the new filter: `[Mess] | [Tiffin]`.
   - In their Profile, a new optional field appears: `Delivery Address & Room No` (if they ever subscribe to a tiffin service).

---

### B. How New Users Experience V2
1. **Landing / Role Selection Screen (`role_selection_page.dart`):**
   - Strictly keeps **only 2 elegant cards** to avoid visual clutter:
     - `Card 1: Mess & Tiffin Owner / Partner`
     - `Card 2: Diner & Student Member`
2. **If Card 1 is tapped:**
   - Bottom sheet asks:
     - `[👑 I am a Mess / Tiffin Owner]` -> Opens `OwnerSetupPage`.
     - `[🛵 I am Delivery Staff / Partner]` -> Opens `StaffInviteCodePage` (enter 6-digit code).
3. **In `OwnerSetupPage`:**
   - Step 0 includes the 3-way segmented pill:  
     `[ 🍽️ Dine-in Mess ] | [ 🛵 Tiffin Delivery ] | [ 🌟 Both (Hybrid) ]`
   - Dynamically adapts: asks for seating capacity for mess, or daily packing capacity + delivery radius for tiffins.

---

### C. Database Schema Deltas (Firestore / Models)

#### 1. `MessModel` Updates (`lib/models/app_models.dart`):
```dart
// Added in V2 (with safe backward-compatible defaults):
final String serviceType; // 'dine_in' (default) | 'tiffin_delivery' | 'both'
final double deliveryRadiusKm; // e.g. 3.5 (default: 0.0)
final double singleMealRate; // e.g. 85.0 (for pay-per-meal diners)
final List<String> activeDeliveryStaffIds; // list of staff UIDs
```

#### 2. `StudentModel` Updates:
```dart
// Added in V2 (optional fields for delivery):
final String? deliveryHostelOrBuilding; // e.g. "Sunrise Boys PG"
final String? deliveryRoomOrFlat; // e.g. "Room 204, 2nd Floor"
final String? deliveryLandmark; // e.g. "Near City Hospital"
final String? deliveryInstructions; // e.g. "Leave on guard table"
```

#### 3. New `StaffInviteModel`:
```dart
class StaffInviteModel {
  final String inviteCode; // 6-digit PIN e.g. "582914"
  final String messId;
  final String ownerId;
  final String staffName; // e.g. "Ramesh"
  final DateTime createdAt;
  final DateTime expiresAt; // createdAt + 15 minutes
  final bool isClaimed;
}
```

---

## 7. STEP-BY-STEP IMPLEMENTATION CHECKLIST FOR V2

When ready to start V2 development, execute in this order:

- [ ] **Step 1: Models & Schema Extension**
  - Add `serviceType`, `deliveryRadiusKm`, `singleMealRate` to `MessModel` with fallback defaults in `fromMap()`.
  - Add delivery address fields to `StudentModel`.
  - Create `StaffInviteModel`.

- [ ] **Step 2: Role Selection & Staff Code Entry**
  - In `role_selection_page.dart`: Add modal bottom sheet on Card 1 tap (`Owner` vs `Staff`).
  - Create `lib/views/pages/auth/staff_invite_page.dart` for 6-digit PIN entry with 15-minute countdown timer.

- [ ] **Step 3: Owner Setup & Settings Adaptations**
  - In `owner_setup_page.dart`: Add `serviceType` toggle in Step 0.
  - Show packing capacity and delivery radius slider when `tiffin_delivery` or `both` is selected.
  - In `owner_settings_page.dart`: Add "Manage Delivery Staff" section with `+ Add Staff` (generates 15-minute PIN).

- [ ] **Step 4: The Delivery Partner Mobile View**
  - Create `lib/views/pages/staff/delivery_partner_main_page.dart`.
  - Building-wise grouped route checklist.
  - Tap `Delivered` toggle, direct phone call button, and bottom cash collection reconciliation.

- [ ] **Step 5: Diner Discover & Pay-Per-Meal Flow**
  - In `discover_page.dart`: Add top filter `[Dine-in Messes] | [Tiffin Services]`.
  - In Tiffin details sheet: Add `Order Single Tiffin (Cash on Delivery)` button for non-members.
  - Post-delivery rating & `[Switch to Monthly]` conversion prompt.

- [ ] **Step 6: End-to-End Testing & Play Store Deployment**
  - Verify existing V1 mess owners update without any migration errors.
  - Verify offline PDF generation remains intact.
  - Publish Mezzo 2.0 release!

---
*(End of Blueprint — Document permanently saved as VERSION_2_BLUEPRINT.md)*

