// Run on a connected device or emulator:
//   flutter test integration_test/app_e2e_test.dart
//
// Or with a specific device:
//   flutter test integration_test/app_e2e_test.dart -d <device-id>

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:english_learning_ap/core/di/service_locator.dart';
import 'package:english_learning_ap/features/learning/data/data.dart';
import 'package:english_learning_ap/features/learning/domain/entities/learning_item.dart';
import 'package:english_learning_ap/features/pronunciation/presentation/presentation.dart';
import 'package:english_learning_ap/main.dart';

import 'fakes/fake_notification_service.dart';
import 'fakes/fake_speech_to_text_service.dart';
import 'fakes/fake_text_to_speech_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const String _testBoxName = 'test_learning_items_box';
final FakeNotificationService _fakeNotificationService =
    FakeNotificationService();
final FakeTextToSpeechService _fakeTextToSpeechService =
    FakeTextToSpeechService();
final FakeSpeechToTextService _fakeSpeechToTextService =
    FakeSpeechToTextService();

/// Initialise the app with a fresh, empty Hive box and fake native services,
/// then pump the widget tree so the home screen is fully visible.
Future<void> _launchApp(WidgetTester tester) async {
  await tester.pumpWidget(const EnglishLearningApp());
  await tester.pumpAndSettle();
}

Future<void> _addItem(
  WidgetTester tester, {
  required String text,
  required String meaning,
  String examples = 'Example sentence.',
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.widgetWithText(TextFormField, 'Texto en ingles'),
    text,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Significado en espanol'),
    meaning,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Ejemplos (uno por linea)'),
    examples,
  );

  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

Future<void> _openPronunciationWithEmptyItems(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<PronunciationCubit>(
        create:
            (_) => PronunciationCubit(
              textToSpeechService: ServiceLocator.textToSpeechService,
              speechToTextService: ServiceLocator.speechToTextService,
              pronunciationEvaluator: ServiceLocator.pronunciationEvaluator,
            ),
        child: const PronunciationScreen(items: <LearningItem>[]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ServiceLocator.initForTest(
      notificationServiceOverride: _fakeNotificationService,
      textToSpeechServiceOverride: _fakeTextToSpeechService,
      speechToTextServiceOverride: _fakeSpeechToTextService,
    );
  });

  setUp(() async {
    final Box<LearningItemModel> box = Hive.box<LearningItemModel>(_testBoxName);
    await box.clear();
    _fakeTextToSpeechService.reset();
    _fakeSpeechToTextService.reset();
  });

  // -------------------------------------------------------------------------
  // Home screen — empty state
  // -------------------------------------------------------------------------
  group('Home screen – empty state', () {
    testWidgets('shows empty-state message and demo button', (tester) async {
      await _launchApp(tester);

      expect(find.text('Agrega tu primera frase'), findsOneWidget);
      expect(find.text('Cargar demo rápida'), findsOneWidget);
    });

    testWidgets('shows app bar with title and action buttons', (tester) async {
      await _launchApp(tester);

      expect(find.text('Agregar frase'), findsOneWidget);
      expect(find.text('Cargar demo rápida'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Adding a learning item
  // -------------------------------------------------------------------------
  group('Add learning item', () {
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

      await _addItem(
        tester,
        text: 'Nice to meet you',
        meaning: 'Mucho gusto',
        examples: 'Nice to meet you, I am Mario.',
      );

      // Back on home screen, item is visible
      expect(find.text('Nice to meet you'), findsOneWidget);
      expect(find.text('Mucho gusto'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Editing a learning item
  // -------------------------------------------------------------------------
  group('Edit learning item', () {
    testWidgets('tapping a list item opens edit form pre-filled', (tester) async {
      await _launchApp(tester);

      // Add an item first
      await _addItem(tester, text: 'Good morning', meaning: 'Buenos dias',
      );

      // Tap the item to edit it
      await tester.tap(find.text('Good morning'));
      await tester.pumpAndSettle();

      expect(find.text('Editar frase'), findsOneWidget);
      // Fields should already contain the saved values
      expect(find.widgetWithText(TextFormField, 'Good morning'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Buenos dias'), findsOneWidget);
    });

    testWidgets('editing and saving updates the item in the list', (tester) async {
      await _launchApp(tester);

      // Add an item
      await _addItem(tester, text: 'Old text', meaning: 'Texto viejo');

      // Open the edit form
      await tester.tap(find.text('Old text'));
      await tester.pumpAndSettle();

        // Update the first field (English text). enterText replaces prior value.
        final Finder englishTextField = find.byType(TextFormField).first;
        await tester.enterText(englishTextField, 'New text');

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
    testWidgets('tapping delete icon removes the item from the list', (tester) async {
      await _launchApp(tester);

      // Add an item
      await _addItem(tester, text: 'To be deleted', meaning: 'Para borrar');

      expect(find.text('To be deleted'), findsOneWidget);

      // Tap the delete icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('To be deleted'), findsNothing);
      expect(find.text('Agrega tu primera frase'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Demo items
  // -------------------------------------------------------------------------
  group('Demo items', () {
    testWidgets('loading demo items populates the list', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.text('Cargar demo rápida'));
      await tester.pumpAndSettle();

      // All three demo phrases should be visible
      expect(find.text('How are you doing today?'), findsOneWidget);
      expect(find.text('I would like a cup of coffee.'), findsOneWidget);
      expect(find.text('Practice makes perfect.'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Review flow
  // -------------------------------------------------------------------------
  group('Review flow', () {
    testWidgets('tapping review icon opens the review screen', (tester) async {
      await _launchApp(tester);

      await tester.tap(find.text('Cargar demo rápida'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
      await tester.pumpAndSettle();

      // Either shows cards or "no items" message — both are the ReviewScreen
      final bool hasCards = tester.any(find.text('No recordé'));
      final bool hasEmpty =
          tester.any(find.text('No tienes elementos pendientes para hoy.'));
      expect(hasCards || hasEmpty, isTrue);
    });

    testWidgets('review session shows all quality options with due items',
        (tester) async {
      await _launchApp(tester);

      // Load demo items – all have nextReviewDate = now, so they are due
      await tester.tap(find.text('Cargar demo rápida'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
      await tester.pumpAndSettle();

      expect(find.text('No recordé'), findsOneWidget);
      expect(find.text('Más o menos'), findsOneWidget);
      expect(find.text('Fácil'), findsOneWidget);
    });

    testWidgets('answering Facil advances to the next card or completes review',
        (tester) async {
      await _launchApp(tester);

        await tester.tap(find.text('Cargar demo rápida'));
      await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
      await tester.pumpAndSettle();

        // Answer all cards with "Fácil" until the session is done
        while (tester.any(find.text('Fácil'))) {
          await tester.tap(find.text('Fácil'));
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
    testWidgets('tapping pronunciation icon without items shows empty message',
        (tester) async {
        await _openPronunciationWithEmptyItems(tester);

      expect(find.text('Pronunciacion'), findsOneWidget);
      expect(find.text('No hay frases para practicar.'), findsOneWidget);
    });

    testWidgets('tapping pronunciation icon with items shows the phrase card',
        (tester) async {
      await _launchApp(tester);

      await tester.tap(find.text('Cargar demo rápida'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.record_voice_over_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Pronunciación'), findsOneWidget);
      expect(find.text('Frase a practicar'), findsOneWidget);
      expect(find.text('Escuchar frase (TTS)'), findsOneWidget);
      expect(find.text('Grabar y evaluar (STT)'), findsOneWidget);
    });

    testWidgets('tapping TTS plays the selected phrase', (tester) async {
      await _launchApp(tester);

      await _addItem(tester, text: 'Nice to meet you', meaning: 'Mucho gusto');

      await tester.tap(find.byIcon(Icons.record_voice_over_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Escuchar frase (TTS)'));
      await tester.pumpAndSettle();

      expect(_fakeTextToSpeechService.spokenTexts, <String>[
        'Nice to meet you',
      ]);
      expect(find.text('Nice to meet you'), findsWidgets);
    });

    testWidgets('recording can be cancelled and returns to main view', (
      tester,
    ) async {
      await _launchApp(tester);

      final Completer<String?> pendingRecognition = Completer<String?>();
      _fakeSpeechToTextService.enqueueDeferredResult(pendingRecognition.future);

      await _addItem(tester, text: 'Good evening', meaning: 'Buenas noches');

      await tester.tap(find.byIcon(Icons.record_voice_over_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grabar y evaluar (STT)'));
      await tester.pump();

      expect(find.text('Graba tu pronunciación'), findsOneWidget);
      expect(find.text('Cancelar grabación'), findsOneWidget);

      await tester.tap(find.text('Cancelar grabación'));
      await tester.pumpAndSettle();

      pendingRecognition.complete('Good evening');
      await tester.pumpAndSettle();

      expect(find.text('Escuchar frase (TTS)'), findsOneWidget);
      expect(find.text('Grabar y evaluar (STT)'), findsOneWidget);
      expect(find.text('Resultado'), findsNothing);
    });

    testWidgets(
      'successful recording shows result and advances to next phrase',
      (tester) async {
        await _launchApp(tester);

        _fakeSpeechToTextService.enqueueResult('How are you doing today?');

        await tester.tap(find.text('Cargar demo rápida'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.record_voice_over_rounded));
        await tester.pumpAndSettle();

        expect(find.text('1 de 3'), findsOneWidget);
        expect(find.text('How are you doing today?'), findsWidgets);

        await tester.tap(find.text('Grabar y evaluar (STT)'));
        await tester.pumpAndSettle();

        expect(find.text('Resultado'), findsOneWidget);
        expect(find.text('Tu dijiste:'), findsOneWidget);
        expect(find.text('Frase correcta:'), findsOneWidget);
        expect(find.text('Muy bien'), findsOneWidget);
        expect(find.text('Siguiente frase'), findsOneWidget);

        await tester.tap(find.text('Siguiente frase'));
        await tester.pumpAndSettle();

        expect(find.text('2 de 3'), findsOneWidget);
        expect(find.text('I would like a cup of coffee.'), findsWidgets);
        expect(find.text('Resultado'), findsNothing);
      },
    );

    testWidgets('retry from result records again and refreshes the score', (
      tester,
    ) async {
      await _launchApp(tester);

      _fakeSpeechToTextService
        ..enqueueResult('Practice makes perfect')
        ..enqueueResult('Practice makes perfect.');

      await _addItem(
        tester,
        text: 'Practice makes perfect.',
        meaning: 'La práctica hace al maestro.',
      );

      await tester.tap(find.byIcon(Icons.record_voice_over_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grabar y evaluar (STT)'));
      await tester.pumpAndSettle();

      expect(find.text('Resultado'), findsOneWidget);
      expect(find.text('Volver a intentar'), findsOneWidget);

      await tester.tap(find.text('Volver a intentar'));
      await tester.pumpAndSettle();

      expect(find.text('Resultado'), findsOneWidget);
      expect(_fakeSpeechToTextService.listenCount, 2);
      expect(find.text('Practice makes perfect.'), findsWidgets);
    });

    testWidgets('last phrase can finish and return to the home screen', (
      tester,
    ) async {
      await _launchApp(tester);

      _fakeSpeechToTextService.enqueueResult('Only one phrase');

      await _addItem(
        tester,
        text: 'Only one phrase',
        meaning: 'Solo una frase',
      );

      await tester.tap(find.byIcon(Icons.record_voice_over_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grabar y evaluar (STT)'));
      await tester.pumpAndSettle();

      expect(find.text('Finalizar'), findsOneWidget);

      await tester.tap(find.text('Finalizar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('English Learning'), findsOneWidget);
      expect(find.text('Only one phrase'), findsOneWidget);
    });

    testWidgets('failed recognition shows an error and allows trying again', (
      tester,
    ) async {
      await _launchApp(tester);

      _fakeSpeechToTextService.enqueueResult(null);

      await _addItem(tester, text: 'See you later', meaning: 'Nos vemos luego');

      await tester.tap(find.byIcon(Icons.record_voice_over_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grabar y evaluar (STT)'));
      await tester.pumpAndSettle();

      expect(find.text('No se detecto voz. Intenta de nuevo.'), findsOneWidget);
      expect(find.text('Escuchar frase (TTS)'), findsOneWidget);
      expect(find.text('Grabar y evaluar (STT)'), findsOneWidget);
    });
  });
}
