# MessMate 🍽️

MessMate is a comprehensive and modern Flutter application designed to streamline the management of hostel messes, PGs, and tiffin services. It bridges the gap between mess owners and students, bringing transparency to attendance, automated billing, and daily menu planning.

## 🌟 Key Features

### For Mess Owners
- **Effortless Student Management:** Add students quickly using a secure 6-digit Mess Code. Track their active status, room numbers, and contact details.
- **Smart Menu Planner:** A visual 7-day menu planner with an integrated dish catalog. Add breakfast, lunch, snacks, and dinner with high-quality images.
- **Automated Billing & Deductions:** Automatically calculates end-of-month bills based on the base monthly fee, subtracting any skipped meals (absents) and adding guest meal charges.
- **Payment Tracking:** Mark bills as paid with a single tap and send quick WhatsApp reminders for pending dues.
- **Absence Tracking & Emergency Controls:** View exactly who is eating today and who skipped. Send bulk announcements or declare a "Mess Closed" day for emergencies.

### For Students
- **Daily Menu Dashboard:** View today's menu at a glance with beautiful, mouth-watering images of the dishes.
- **Meal Skipping (Absents):** Mark yourself absent for upcoming meals if you are eating out or going home. The cost is automatically deducted from your monthly bill!
- **Billing Transparency:** View a detailed breakdown of your monthly bill, including base fees, deductions for skipped meals, and extra guest charges.
- **Leave History:** A complete calendar history of your past absences and meal records.

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **State Management:** Riverpod
- **Backend (BaaS):** Firebase (Firestore, Storage, Authentication)
- **Design:** Custom UI with modern aesthetics, glassmorphism elements, and `GoogleFonts`.
- **Scripts:** Node.js utilities for backend database seeding and fetching high-quality dish images via the Google Custom Search API.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (`>=3.0.0`)
- Dart SDK
- A Firebase Project with Firestore and Storage enabled.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/mohit-agnihotri/MessMate.git
   cd MessMate
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Ensure you have your own `firebase_options.dart` generated via the FlutterFire CLI, and place it in the `lib/` directory.

4. **Run the App:**
   ```bash
   flutter run
   ```

## 🔒 Security

MessMate is built with security as a core principle at every layer:

- **📱 Phone OTP Authentication:** Users can only sign in via their verified phone number using Firebase Authentication. No passwords, no email guessing — only a real OTP sent to your phone.
- **🎟️ Mess Code System:** Students can only join a mess by entering a private 6-digit Mess Code shared by the owner. No one can enter a mess without the owner's permission.
- **🛡️ Role-Based Data Access (Firestore Rules):** Every collection in the database is protected by strict Firestore Security Rules:
  - A **student** can only read/write their own data (meal records, leaves, bill).
  - An **owner** can only manage data belonging to their own mess.
  - **No cross-mess data access** is possible — an owner of Mess A cannot see data of Mess B.
  - The `global_dishes` collection is **read-only** for all users; only backend scripts can write to it.
  - Bills can **never be deleted** via the app — this prevents billing fraud.
- **🔐 No Secrets in Code:** Firebase configuration, Google API Keys, and Service Account credentials are never hardcoded in the app or uploaded to this repository.


---
*Built with ❤️ for a better hostel life.*
