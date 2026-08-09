# Google Cloud Console & OAuth Setup Guide

## 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project (e.g., `debt-tracker`).

## 2. Enable APIs

In **APIs & Services → Library**, enable:
- **Google Sheets API**
- **Google Drive API**
- **Google People API** (required by Google Sign-In to load the user profile)

## 3. Configure OAuth Consent Screen

1. Go to **APIs & Services → OAuth consent screen**.
2. Choose **External** (or Internal if your organisation is on Google Workspace).
3. Fill in App name, support email, and developer contact.
4. Add the following **scope**:
   - `https://www.googleapis.com/auth/drive.file`

   This scope limits the app to files it creates or that the user explicitly
   opens with it — the app cannot access any other files on the user's Drive.
5. Add test users while the app is in testing mode.

## 4. Create OAuth Credentials

### Android

1. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
2. Choose **Android**.
3. Enter the package name `com.heww.depts`.
4. Run `keytool -keystore ~/.android/debug.keystore -list -v` and paste the **SHA-1** fingerprint.

### iOS

1. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
2. Choose **iOS**.
3. Enter your Bundle ID (e.g., `com.example.depts`).
4. Download `GoogleService-Info.plist` and add it to `ios/Runner/` via Xcode.
5. In `ios/Runner/Info.plist`, add the `CFBundleURLTypes` entry with the reversed client ID from the plist.

### Web

1. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
2. Choose **Web application**.
3. Add the app URL to **Authorized JavaScript origins**, for example
  `http://localhost:7357` for local development.
4. Copy the generated client ID. A Desktop, Android, or iOS client ID cannot
  be used for Flutter web.

## 5. iOS Info.plist URL Scheme

Add the reversed client ID as a URL scheme in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Replace `YOUR_CLIENT_ID` with the reversed client ID from `GoogleService-Info.plist`
(field `REVERSED_CLIENT_ID`).

## 6. Run the App

For Android or iOS:

```bash
flutter pub get
flutter run
```

For web, use the same port configured as an authorized JavaScript origin and
provide the Web application client ID:

```bash
flutter run -d chrome --web-port 7357 --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```
