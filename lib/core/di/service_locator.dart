import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/services.dart';
import '../../features/learning/data/data.dart';
import '../../features/learning/domain/domain.dart';
import '../../features/pronunciation/domain/domain.dart';
import '../../features/review/domain/domain.dart';

class ServiceLocator {
  ServiceLocator._();

  static late final LearningRepository learningRepository;
  static late final GetAllLearningItemsUseCase getAllLearningItemsUseCase;
  static late final AddLearningItemUseCase addLearningItemUseCase;
  static late final UpdateLearningItemUseCase updateLearningItemUseCase;
  static late final DeleteLearningItemUseCase deleteLearningItemUseCase;
  static late final GetItemsToReviewUseCase getItemsToReviewUseCase;
  static late final SpacedRepetitionService spacedRepetitionService;
  static late final GetDueReviewItemsUseCase getDueReviewItemsUseCase;
  static late final SubmitReviewUseCase submitReviewUseCase;
  static late final TextToSpeechService textToSpeechService;
  static late final SpeechToTextService speechToTextService;
  static late final NotificationService notificationService;
  static late final PronunciationEvaluator pronunciationEvaluator;

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LearningItemAdapter());
    }

    final Box<LearningItemModel> learningBox =
        await Hive.openBox<LearningItemModel>('learning_items_box');

    final LearningLocalDataSource localDataSource =
        LearningLocalDataSourceImpl(learningBox: learningBox);
    learningRepository = LearningRepositoryImpl(localDataSource: localDataSource);

    getAllLearningItemsUseCase = GetAllLearningItemsUseCase(learningRepository);
    addLearningItemUseCase = AddLearningItemUseCase(learningRepository);
    updateLearningItemUseCase = UpdateLearningItemUseCase(learningRepository);
    deleteLearningItemUseCase = DeleteLearningItemUseCase(learningRepository);
    getItemsToReviewUseCase = GetItemsToReviewUseCase(learningRepository);

    spacedRepetitionService = SpacedRepetitionService();
    getDueReviewItemsUseCase = GetDueReviewItemsUseCase(learningRepository);
    submitReviewUseCase = SubmitReviewUseCase(
      repository: learningRepository,
      spacedRepetitionService: spacedRepetitionService,
    );

    textToSpeechService = FlutterTextToSpeechService(FlutterTts());
    speechToTextService = FlutterSpeechToTextService(SpeechToText());
    notificationService =
        FlutterNotificationService(FlutterLocalNotificationsPlugin());
    await textToSpeechService.initialize();
    await speechToTextService.initialize();
    await notificationService.initialize();
    pronunciationEvaluator = PronunciationEvaluator();
  }

  /// Initialises the locator for widget / integration tests.
  ///
  /// Uses a separate Hive box (`test_learning_items_box`) that is cleared on
  /// every call so each test starts with a clean slate.  Native-platform
  /// services (notifications, TTS, STT) must be supplied as test doubles via
  /// the override parameters.
  ///
  /// [hivePath] must be supplied for pure widget tests (e.g. a temp directory
  /// from `Directory.systemTemp.createTempSync()`).  When running as a real
  /// integration test on a device, pass `null` to use `Hive.initFlutter()`.
  static Future<void> initForTest({
    required NotificationService notificationServiceOverride,
    required TextToSpeechService textToSpeechServiceOverride,
    required SpeechToTextService speechToTextServiceOverride,
    String? hivePath,
  }) async {
    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LearningItemAdapter());
    }

    const String testBoxName = 'test_learning_items_box';
    if (Hive.isBoxOpen(testBoxName)) {
      await Hive.box<LearningItemModel>(testBoxName).clear();
    } else {
      final Box<LearningItemModel> box =
          await Hive.openBox<LearningItemModel>(testBoxName);
      await box.clear();
    }

    final Box<LearningItemModel> learningBox =
        Hive.box<LearningItemModel>(testBoxName);

    final LearningLocalDataSource localDataSource =
        LearningLocalDataSourceImpl(learningBox: learningBox);
    learningRepository = LearningRepositoryImpl(localDataSource: localDataSource);

    getAllLearningItemsUseCase = GetAllLearningItemsUseCase(learningRepository);
    addLearningItemUseCase = AddLearningItemUseCase(learningRepository);
    updateLearningItemUseCase = UpdateLearningItemUseCase(learningRepository);
    deleteLearningItemUseCase = DeleteLearningItemUseCase(learningRepository);
    getItemsToReviewUseCase = GetItemsToReviewUseCase(learningRepository);

    spacedRepetitionService = SpacedRepetitionService();
    getDueReviewItemsUseCase = GetDueReviewItemsUseCase(learningRepository);
    submitReviewUseCase = SubmitReviewUseCase(
      repository: learningRepository,
      spacedRepetitionService: spacedRepetitionService,
    );

    textToSpeechService = textToSpeechServiceOverride;
    speechToTextService = speechToTextServiceOverride;
    notificationService = notificationServiceOverride;
    pronunciationEvaluator = PronunciationEvaluator();
  }
}
