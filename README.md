# Wash Delivery

Daily laundry tracking app for Android and Windows.  
Each employee records items per client throughout the day. At the end of the day, the employer reviews a full monthly summary grouped by date and client.

Built with **Flutter + Firebase Firestore** — real-time sync across all devices.

---

## Download

Every push to `main` automatically builds both files via GitHub Actions:

| File | Platform |
|---|---|
| `WashDelivery_Setup.exe` | Windows installer |
| `app-release.apk` | Android |

Go to **Actions → latest run → Artifacts** to download.

---

## Features

- **Multi-device sync** — Firestore streams update all devices in real time
- **Employee selection** — each employee works under their own name
- **Client + product tracking** — integer quantities, custom products supported
- **Monthly summary** — navigate months, entries grouped by date then client
- **Admin PIN** — protects employee/client/product management (default PIN: `1234`)
- **Greek language UI**

---

## Screens

| Screen | Access | Description |
|---|---|---|
| Home | Everyone | Navigate to entry or summary |
| Select Employee | Everyone | Pick your name |
| Add Entry | Everyone | Record client + product + quantity; edit/delete your own entries |
| Monthly Summary | Everyone | All clients grouped by date for the selected month |
| Manage | Admin only | Add/edit/delete employees, clients, products |

---

## Tech stack

- Flutter 3.44.2 (stable)
- Firebase Firestore (real-time database)
- Material 3 theme
- GitHub Actions CI (builds APK + Windows installer)
- Inno Setup (Windows installer packaging)

---

## Firebase setup

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name `com.akarekla.washer_app`
3. Download `google-services.json` → place at `android/app/google-services.json`
4. Generate `lib/firebase_options.dart` using FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. In Firestore → Rules, set open access for internal use:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```

---

## GitHub Actions secrets required

| Secret | Content |
|---|---|
| `FIREBASE_OPTIONS_DART` | Contents of `lib/firebase_options.dart` |
| `GOOGLE_SERVICES_JSON` | Contents of `android/app/google-services.json` |

Add them at **Settings → Secrets and variables → Actions**.

---

## Local development

```bash
flutter pub get
flutter run                          # Android (USB or wireless)
flutter build apk --release          # Android APK
flutter build windows --release      # Windows (requires Windows machine)
```

---

## Firestore data model

```
/entries/{id}
  employeeName  : string
  clientName    : string
  productName   : string
  quantity      : number
  date          : string      # "YYYY-MM-DD"
  createdAtMs   : number      # client timestamp ms (used for sort order)
  createdAt     : timestamp   # server timestamp

/employees/{id}   name : string
/clients/{id}     name : string
/products/{id}    name : string
/settings/admin   pin  : string
```

---

## Project structure

```
lib/
├── main.dart
├── firebase_options.dart          # gitignored — injected via CI secret
├── models/
│   └── entry.dart
├── services/
│   ├── firestore_service.dart
│   └── admin_service.dart
└── screens/
    ├── home_screen.dart
    ├── select_employee_screen.dart
    ├── add_entry_screen.dart
    ├── summary_screen.dart
    └── manage_screen.dart
```
