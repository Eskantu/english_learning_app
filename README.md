# English Learning AP

English Learning AP is a Flutter app to help users practice English phrases through:

- Phrase management (add, edit, delete)
- Daily review reminders
- Spaced repetition review flow
- Pronunciation practice (TTS + STT + similarity scoring)

The app is built with a clean architecture style and local persistence, so it can run fully offline.

## Main Features

### 1. Learning Items (CRUD)

- Add new phrases with meaning and examples
- Edit existing phrases
- Delete phrases
- Seed demo data for quick onboarding

### 2. Daily Review Flow

- Items due for review are selected based on `nextReviewDate`
- Review session supports quality feedback levels:
	- No recorde
	- Mas o menos
	- Facil
- Review updates schedule using spaced repetition rules

### 3. Notification Reminder

- A local notification is scheduled daily if there are pending review items
- If there are no pending items, the reminder is canceled
- Tapping the notification opens the review flow (`open_review` payload)

### 4. Pronunciation Practice

- Listen to phrase with Text-to-Speech
- Record pronunciation with Speech-to-Text
- Evaluate spoken text with string similarity and return feedback

## Tech Stack

- Flutter (Dart)
- BLoC/Cubit (`flutter_bloc`)
- Local database with Hive (`hive`, `hive_flutter`)
- Local notifications (`flutter_local_notifications`)
- Text to speech (`flutter_tts`)
- Speech to text (`speech_to_text`)

## Project Structure

The codebase follows feature-first organization with domain/data/presentation layers.

```text
lib/
	core/
		constants/
		di/
		services/
		utils/
	features/
		learning/
			data/
			domain/
			presentation/
		review/
			data/
			domain/
			presentation/
		pronunciation/
			data/
			domain/
			presentation/
	main.dart
```

## Requirements

- Flutter SDK compatible with this project
- Dart SDK: `^3.7.0`
- Android Studio (for Android emulator/device testing)
- Java 11+

### Android Notes

This project is configured for:

- `minSdk = 24` (required by `flutter_tts`)
- Core library desugaring enabled (required by `flutter_local_notifications`)

## Setup

1. Clone repository
2. Install dependencies:

```bash
flutter pub get
```

3. Check environment:

```bash
flutter doctor
```

## Run the App

List devices:

```bash
flutter devices
```

Run on selected device:

```bash
flutter run -d <device-id>
```

## Testing

### Unit / Widget tests

```bash
flutter test
```

### End-to-End (integration) tests

The project contains an E2E suite at:

- `integration_test/app_e2e_test.dart`

Run on Android emulator/device:

```bash
flutter test integration_test/app_e2e_test.dart -d <android-device-id>
```

Example:

```bash
flutter test integration_test/app_e2e_test.dart -d emulator-5554
```

## Notification Behavior

- Frequency: daily
- Trigger condition: only if `dueCount > 0`
- Selected items: all items where `nextReviewDate` is on or before end of current day
- Action: payload `open_review` opens review screen

## Development Guidelines

- Keep logic in domain/usecases and keep widgets focused on UI
- Prefer extending existing feature folders over creating cross-feature coupling
- Add/maintain tests when changing business behavior
- Keep user-facing copy consistent (currently mostly Spanish labels)

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter test integration_test/app_e2e_test.dart -d emulator-5554
```

## License

Private/internal project. Add a license file if you plan to open source it.
