# Depts

Приложение для учёта долгов с синхронизацией через Google Sheets. Написано на Flutter и работает на Android, iOS, вебе и десктопе.

## Описание

Depts помогает отслеживать, кто и сколько вам должен (и кому должны вы):

- Учёт людей и их долгов (`lib/models/person_debt.dart`)
- История транзакций по каждому человеку (`lib/models/debt_transaction.dart`)
- Вход через аккаунт Google (Google Sign-In)
- Хранение и синхронизация данных в Google Sheets — таблица создаётся автоматически в вашем Google Drive
- Управление состоянием через BLoC (`flutter_bloc`)

Приложение использует scope `https://www.googleapis.com/auth/drive.file`, поэтому имеет доступ только к файлам, которые создало само.

## Структура проекта

```
lib/
├── main.dart          # Точка входа
├── blocs/             # BLoC-логика (auth, sheets)
├── models/            # Модели данных
├── screens/           # Экраны приложения
└── services/          # Работа с Google Sheets API
```

## Требования

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x (Dart >= 3.0.0)
- Аккаунт Google и проект в Google Cloud Console (см. [docs/google_cloud_setup.md](docs/google_cloud_setup.md))
- Для Android: Android Studio / Android SDK
- Для iOS: macOS с Xcode и CocoaPods

## Подготовка

1. Клонируйте репозиторий и установите зависимости:

   ```bash
   git clone https://github.com/HewwN/depts.git
   cd depts
   flutter pub get
   ```

2. Настройте Google Cloud проект и OAuth-учётные данные по инструкции в
   [docs/google_cloud_setup.md](docs/google_cloud_setup.md) — без этого вход через Google работать не будет.

## Сборка для Android

Пакет приложения: `com.heww.depts`.

1. Создайте OAuth client ID типа **Android** в Google Cloud Console:
   - укажите package name `com.heww.depts`;
   - добавьте SHA-1 отпечаток ключа подписи:

     ```bash
     # debug-ключ
     keytool -keystore ~/.android/debug.keystore -list -v
     # (пароль по умолчанию: android)
     ```

2. Запуск в режиме отладки:

   ```bash
   flutter run
   ```

3. Сборка релизного APK:

   ```bash
   flutter build apk --release
   ```

   Готовый файл: `build/app/outputs/flutter-apk/app-release.apk`.

4. Сборка App Bundle для Google Play:

   ```bash
   flutter build appbundle --release
   ```

   Готовый файл: `build/app/outputs/bundle/release/app-release.aab`.

> Для релизной сборки настройте собственный ключ подписи и добавьте его SHA-1
> в OAuth client ID (см. [подпись приложения](https://docs.flutter.dev/deployment/android#signing-the-app)).

## Сборка для iOS

Сборка возможна только на macOS с установленным Xcode.

1. Установите зависимости CocoaPods:

   ```bash
   cd ios
   pod install
   cd ..
   ```

2. Создайте OAuth client ID типа **iOS** в Google Cloud Console:
   - укажите Bundle ID вашего приложения;
   - скачайте `GoogleService-Info.plist` и добавьте его в `ios/Runner/` через Xcode;
   - в `ios/Runner/Info.plist` добавьте `CFBundleURLTypes` с reversed client ID из plist-файла.

3. Откройте проект в Xcode и настройте подпись:

   ```bash
   open ios/Runner.xcworkspace
   ```

   В разделе **Signing & Capabilities** выберите свою команду разработчика (Team).

4. Запуск в режиме отладки:

   ```bash
   flutter run
   ```

5. Релизная сборка:

   ```bash
   flutter build ipa --release
   ```

   Архив: `build/ios/archive/Runner.xcarchive`, IPA: `build/ios/ipa/`.
   Загрузить в App Store можно через Xcode или [Transporter](https://apps.apple.com/app/transporter/id1450874784)
   (см. [публикация в App Store](https://docs.flutter.dev/deployment/ios)).

## Тесты

```bash
flutter test
```

## Полезные ссылки

- [Настройка Google Cloud и OAuth](docs/google_cloud_setup.md)
- [Документация Flutter](https://docs.flutter.dev/)
- [Деплой Android](https://docs.flutter.dev/deployment/android)
- [Деплой iOS](https://docs.flutter.dev/deployment/ios)
