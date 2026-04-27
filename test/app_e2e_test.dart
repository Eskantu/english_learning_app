// Widget-level E2E tests – no device or emulator required.
// Run with:
//   flutter test test/app_e2e_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:english_learning_ap/core/di/service_locator.dart';
import 'package:english_learning_ap/main.dart';

import '../integration_test/fakes/fake_notification_service.dart';
import '../integration_test/fakes/fake_speech_to_text_service.dart';
import '../integration_test/fakes/fake_text_to_speech_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late Directory _hiveDir;

/// Set up a fresh Hive temp directory and initialise all services with fakes.
/// Call this at the top of every [testWidgets] body (or in [setUp]).
Future<void> _launchApp(WidgetTester tester) async {
  // Each test gets its own temp dir so boxes are always empty
  _hiveDir = Directory.systemTemp.createTempSync('hive_test_');

  await ServiceLocator.initForTest(
    notificationServiceOverride: FakeNotificationService(),
    textToSpeechServiceOverride: FakeTextToSpeechService(),
    speechToTextServiceOverride: FakeSpeechToTextService(),
    hivePath: _hiveDir.path,
  );

  await tester.pumpWidget(const EnglishLearningApp());
  await tester.pumpAndSettle();
}

/// Clean up open Hive boxes after each test.
Future<void> _tearDown() async {
  await Hive.close();
  _hiveDir.deleteSync(recursive: true);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Home screen — empty state
  // -------------------------------------------------------------------------
  group('Home screen – empty state', () {
    tearDown(_tearDown);

    testWidgets('shows empty-state message and demo button', (tester) async {
      await _launchApp(tester);

      expect(find.text('No hay frases guardadas.'), findsOneWidget);
      expect(find.text('Cargar demo rapida'), findsOneWidget);
    });

    testWidgets('shows app bar with title and action buttons', (tester) async {
      await _launchApp(tester);

      expect(find.text('English Learning'), findsOneWidget);
      expect(find.byIcon(Icons.record_voice_over), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Adding a learning item
  // -------------------------------------------------------------------------
  group('Add learning item', () {
    tearDown(_tearDown);

    testWidgets('tapping FAB opens the add-item form', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Agregar frase'), findsOneWidget);
      expect(find.text('Texto en ingles'), findsOneWidget);
      expect(find.text('Significado en espanol'), findsOneWidget);
      expect(find.text('Ejemplos (uno por linea)'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('submitting empty form shows validation errors', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa el texto en ingles.'), findsOneWidget);
      expect(find.text('Ingresa el significado.'), findsOneWidget);
    });

    testWidgets('filling form and saving adds item to home list', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Texto en ingles'),
        'Nice to meet you',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Significado en espanol'),
        'Mucho gusto',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ejemplos (uno por linea)'),
        'Nice to meet you, I am Mario.',
      );

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Nice to meet you'), findsOneWidget);
      expect(find.text('Mucho gusto'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Editing a learning item
  // -------------------------------------------------------------------------
  group('Edit learning item', () {
    tearDown(_tearDown);

    testWidgets('tapping a list item opens edit form pre-filled', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Texto en ingles'),
        'Good morning',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Significado en espanol'),
        'Buenos dias',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Good morning'));
      await tester.pumpAndSettle();

      expect(find.text('Editar frase'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Good morning'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Buenos dias'), findsOneWidget);
    });

    testWidgets('editing and saving updates the item in the list', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Texto en ingles'),
        'Old text',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Significado en espanol'),
        'Texto viejo',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Old text'));
      await tester.pumpAndSettle();

      final Finder textField = find.widgetWithText(TextFormField, 'Old text');
      await tester.tap(textField);
      await tester.pump();
      (tester.widget<TextFormField>(textField).controller)?.clear();
      await tester.enterText(textField, 'New text');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('New text'), findsOneWidget);
      expect(find.text('Old text'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Deleting a learning item
  // -------------------------------------------------------------------------
  group('Delete learning item', () {
    tearDown(_tearDown);

    testWidgets('tapping delete icon removes the item from the list', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Texto en ingles'),
        'To be deleted',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Significado en espanol'),
        'Para borrar',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('To be deleted'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('To be deleted'), findsNothing);
      expect(find.text('No hay frases guardadas.'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Demo items
  // -------------------------------------------------------------------------
  group('Demo items', () {
    tearDown(_tearDown);

    testWidgets('loading demo items populates the list', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.text('Cargar demo rapida'));
      await tester.pumpAndSettle();

      expect(find.text('How are you doing today?'), findsOneWidget);
      expect(find.text('I would like a cup of coffee.'), findsOneWidget);
      expect(find.text('Practice makes perfect.'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Review flow
  // -------------------------------------------------------------------------
  group('Review flow', () {
    tearDown(_tearDown);

    testWidgets('tapping review icon opens the review screen', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      final bool hasCards = tester.any(find.text('No recorde'));
      final bool hasEmpty =
          tester.any(find.text('No tienes elementos pendientes para hoy.'));
      expect(hasCards || hasEmpty, isTrue);
    });

    testWidgets('review session shows all quality options with due items',
        (tester) async {
      await _launchApp(tester);

      await tester.tap(find.text('Cargar demo rapida'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      expect(find.text('No recorde'), findsOneWidget);
      expect(find.text('Mas o menos'), findsOneWidget);
      expect(find.text('Facil'), findsOneWidget);
    });

    testWidgets('answering Facil on all cards completes the review session',
        (tester) async {
      await _launchApp(tester);

      await tester.tap(find.text('Cargar demo rapida'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      while (tester.any(find.text('Facil'))) {
        await tester.tap(find.text('Facil'));
        await tester.pumpAndSettle();
      }

      expect(
        find.text('No tienes elementos pendientes para hoy.'),
        findsOneWidget,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Pronunciation screen
  // -------------------------------------------------------------------------
  group('Pronunciation screen', () {
    tearDown(_tearDown);

    testWidgets('tapping pronunciation icon without items shows empty message',
        (tester) async {
      await _launchApp(tester);

      await tester.tap(find.byIcon(Icons.record_voice_over));
      await tester.pumpAndSettle();

      expect(find.text('Pronunciacion'), findsOneWidget);
      expect(find.text('No hay frases para practicar.'), findsOneWidget);
    });

    testWidgets('tapping pronunciation icon with items shows the dropdown',
        (tester) async {
      await _launchApp(tester);

      await tester.tap(find.text('Cargar demo rapida'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.record_voice_over));
      await tester.pumpAndSettle();

      expect(find.text('Pronunciacion'), findsOneWidget);
      expect(find.text('Frase a practicar'), findsOneWidget);
      expect(find.text('Escuchar frase (TTS)'), findsOneWidget);
      expect(find.text('Grabar y evaluar (STT)'), findsOneWidget);
    });
  });
}
