# Koinonia

Koinonia is a Flutter-based mobile application designed to support church community management activities digitally and efficiently.  
The application provides features for attendance management, financial tracking, worship scheduling, community news, donation recaps, and role-based access for administrators, committee members, and residents.

---

## ✨ Features

### 👤 Authentication & Role Management

- Secure login system using Firebase Authentication
- Role-based access:
  - Master
  - Pengurus (Committee)
  - Warga (Residents)

### 📅 Worship Schedule Management

- Create and manage worship schedules
- OTP-based attendance validation
- Attendance recap for each worship session

### 💰 Financial Management

- Record income and expenses
- Monitor community financial balance
- Donation and contribution tracking

### 📰 Community News & Activities

- Publish and manage activity news
- Donation recap from community activities
- Track sales results from donated goods

### 📊 Statistics & Reports

- Attendance statistics visualization
- User login activity reports
- PDF export for attendance recaps

---

## 🛠️ Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Shared Preferences
- FL Chart
- PDF & Printing Packages

---

## 📂 Project Structure

```bash
lib/
├── pages/
│   ├── master/
│   ├── pengurus/
│   ├── warga/
│   └── common/
├── widgets/
├── services/
├── models/
└── main.dart
```

---

## 🚀 Getting Started

### Prerequisites

Before running the project, ensure you have installed:

- Flutter SDK
- Android Studio / VS Code
- Firebase Project Configuration

Check Flutter installation:

```bash
flutter --version
```

### Installation

1. Clone the repository

```bash
git clone https://github.com/Andreastirta22/Koinonia_app.git
```

2. Navigate to the project folder

```bash
cd koinonia
```

3. Install dependencies

```bash
flutter pub get
```

4. Run the application

```bash
flutter run
```

---

## 🔥 Firebase Configuration

This project uses Firebase services.  
Make sure to configure:

- Firebase Authentication
- Cloud Firestore
- Android/iOS Firebase setup files:
  - `google-services.json`
  - `GoogleService-Info.plist`

---

## 📸 Screenshots

Add application screenshots here.

```bash
assets/screenshots/
```

Example:

- Login Page
- Dashboard
- Financial Report
- Attendance Recap

---

## 📖 Documentation

- Flutter Documentation: https://docs.flutter.dev/
- Firebase Documentation: https://firebase.google.com/docs

---

## 👨‍💻 Developer

Developed by Andreas Tirta  
for church community digitalization and management.

---

## 📄 License

This project is licensed under the MIT License.  
Feel free to use and modify it for educational and non-commercial purposes.
