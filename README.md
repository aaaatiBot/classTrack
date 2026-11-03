# ClassTrack Mobile Application

ClassTrack is a mobile application tailored for teachers (Admin) and learners (Students) to manage classes, attendance, syllabus progression, homework, notes, and academic performance tracking.

---

## 🚀 Architecture & Tech Stack

- **Framework**: Flutter 3.47+ (Dart 3.13+)
- **Architecture**: Feature-First architecture with Riverpod state management & GoRouter
- **Design System**: Material 3 (with custom light & dark themes, single-hand touch ergonomics)
- **Backend**: Supabase (PostgreSQL, Row Level Security, Auth, Storage, Edge Functions)
- **OCR & ML**: Google ML Kit Text Recognition on-device (zero data upload for report cards & test routines)
- **AI Processing**: Gemini API (Free tier via secure Supabase Edge Function)

---

## 📁 Project Structure

```
classTrack/
├── lib/
│   ├── core/
│   │   ├── config/             # Supabase configuration & runtime credentials
│   │   ├── router/             # GoRouter setup with role-based routing (Admin / Student)
│   │   ├── storage/            # Offline caching with SharedPreferences
│   │   ├── theme/              # Material 3 light and dark theme definitions
│   │   └── utils/              # Error handling & paused project detection
│   ├── features/
│   │   ├── auth/               # Internal username@classtrack.app auth & login
│   │   ├── shell/              # AdminShell and StudentShell with bottom navigation
│   │   ├── students/           # Student accounts & management
│   │   ├── attendance/         # Attendance register & student calendar
│   │   ├── syllabus/           # Syllabus & chapter progress tracking
│   │   ├── homework/           # Daily homework postings
│   │   ├── notes/              # Notes & study material downloads
│   │   ├── results/            # Report card OCR & past results
│   │   ├── tests/              # Test routine OCR & local reminders
│   │   ├── test_scores/        # Class test scores & entry
│   │   └── dashboard/          # Analytics, completion rings, trend charts
│   └── main.dart
├── supabase/
│   ├── schema.sql              # Database tables, functions, & indexes
│   ├── rls.sql                 # Row Level Security policies
│   ├── storage.sql             # Private bucket configuration for 'notes'
│   └── seed.sql                # Admin user seed helper
└── test/
    └── widget_test.dart
```

---

## ⚡ Setup Supabase Database

1. Open your [Supabase Project Dashboard](https://supabase.com/dashboard).
2. Go to the **SQL Editor** tab in the left sidebar.
3. Run the SQL scripts in this exact order:
   - `supabase/schema.sql` (Creates all tables, constraints, and helper functions)
   - `supabase/rls.sql` (Applies strict Row Level Security policies)
   - `supabase/storage.sql` (Creates the private `notes` bucket with security rules)
4. Create your initial Admin user:
   - In Supabase Dashboard, go to **Authentication** $\rightarrow$ **Users** $\rightarrow$ **Add User**.
   - Email: `admin@classtrack.app`
   - Password: `<your-secure-admin-password>`
   - Auto Confirm User: Checked
   - Copy the User UID that was generated.
   - Open `supabase/seed.sql`, replace `<ADMIN_USER_UID_HERE>` with your UID, and execute it in SQL Editor.

---

## ⚠️ Supabase Free Tier Inactivity Notice (Paused Projects)

> **Important**: Supabase free-tier projects automatically pause after **7 days of inactivity**.
> 
> If the app shows a warning stating **"Cannot reach Supabase servers"**:
> 1. Log in to [supabase.com/dashboard](https://supabase.com/dashboard).
> 2. Click on your paused `classtrack` project.
> 3. Click **Restore project** (or **Unpause**).
> 4. Once the status shows "Active" (typically 1–2 minutes), reopen or refresh the ClassTrack app.

---

## 🧪 Testing Phase 1

1. Start the app:
   ```powershell
   flutter run
   ```
2. On first launch, click the **Settings icon** (top-right of the login screen) and paste your **Supabase Project URL** and **Public Anon Key**.
3. Log in with:
   - **Username**: `admin`
   - **Password**: `<the-password-you-set>`
4. Notice that:
   - The app automatically appends `@classtrack.app` internally to authenticate with Supabase Auth.
   - The user profile is retrieved from the `profiles` table.
   - You are automatically routed to the **Admin Shell** (`/admin/home`) with bottom navigation:
     - Home, Students, Attendance, Homework & Notes, Test Scores.
   - Tapping the logout button returns you cleanly to the login screen.
