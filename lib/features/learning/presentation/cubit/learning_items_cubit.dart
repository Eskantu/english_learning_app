import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/learning_item.dart';
import '../../domain/usecases/add_learning_item_usecase.dart';
import '../../domain/usecases/delete_learning_item_usecase.dart';
import '../../domain/usecases/get_all_learning_items_usecase.dart';
import '../../domain/usecases/get_items_to_review_usecase.dart';
import '../../domain/usecases/update_learning_item_usecase.dart';
import 'learning_items_state.dart';

class LearningItemsCubit extends Cubit<LearningItemsState> {
  LearningItemsCubit({
    required GetAllLearningItemsUseCase getAllLearningItemsUseCase,
    required AddLearningItemUseCase addLearningItemUseCase,
    required UpdateLearningItemUseCase updateLearningItemUseCase,
    required DeleteLearningItemUseCase deleteLearningItemUseCase,
    required GetItemsToReviewUseCase getItemsToReviewUseCase,
    required NotificationService notificationService,
  })  : _getAllLearningItemsUseCase = getAllLearningItemsUseCase,
        _addLearningItemUseCase = addLearningItemUseCase,
        _updateLearningItemUseCase = updateLearningItemUseCase,
        _deleteLearningItemUseCase = deleteLearningItemUseCase,
        _getItemsToReviewUseCase = getItemsToReviewUseCase,
        _notificationService = notificationService,
        super(const LearningItemsState());

  final GetAllLearningItemsUseCase _getAllLearningItemsUseCase;
  final AddLearningItemUseCase _addLearningItemUseCase;
  final UpdateLearningItemUseCase _updateLearningItemUseCase;
  final DeleteLearningItemUseCase _deleteLearningItemUseCase;
  final GetItemsToReviewUseCase _getItemsToReviewUseCase;
  final NotificationService _notificationService;

  Future<void> loadItems() async {
    emit(state.copyWith(status: LearningItemsStatus.loading, errorMessage: null));
    try {
      final List<LearningItem> items = await _getAllLearningItemsUseCase();
      emit(state.copyWith(status: LearningItemsStatus.success, items: items));
      final List<LearningItem> dueItems = await _getItemsToReviewUseCase(DateTime.now());
      await _notificationService.scheduleDailyReviewReminder(dueCount: dueItems.length);
    } catch (_) {
      emit(
        state.copyWith(
          status: LearningItemsStatus.failure,
          errorMessage: 'No se pudieron cargar los elementos.',
        ),
      );
    }
  }

  Future<void> saveItem(LearningItem item) async {
    try {
      final bool exists = state.items.any((LearningItem e) => e.id == item.id);
      if (exists) {
        await _updateLearningItemUseCase(item);
      } else {
        await _addLearningItemUseCase(item);
      }
      await loadItems();
    } catch (_) {
      emit(
        state.copyWith(
          status: LearningItemsStatus.failure,
          errorMessage: 'No se pudo guardar el elemento.',
        ),
      );
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _deleteLearningItemUseCase(id);
      await loadItems();
    } catch (_) {
      emit(
        state.copyWith(
          status: LearningItemsStatus.failure,
          errorMessage: 'No se pudo eliminar el elemento.',
        ),
      );
    }
  }

  Future<void> seedDemoItems() async {
    final DateTime now = DateTime.now();
    final List<LearningItem> demoItems = <LearningItem>[
      LearningItem(
        id: 'demo-1',
        text: 'How are you doing today?',
        meaning: 'Como te va hoy?',
        examples: const <String>['How are you doing today, my friend?'],
        repetitionLevel: 0,
        nextReviewDate: now,
        createdAt: now,
      ),
      LearningItem(
        id: 'demo-2',
        text: 'I would like a cup of coffee.',
        meaning: 'Me gustaria una taza de cafe.',
        examples: const <String>['I would like a cup of coffee, please.'],
        repetitionLevel: 0,
        nextReviewDate: now,
        createdAt: now,
      ),
      LearningItem(
        id: 'demo-3',
        text: 'Practice makes perfect.',
        meaning: 'La practica hace al maestro.',
        examples: const <String>['Practice makes perfect when you stay consistent.'],
        repetitionLevel: 0,
        nextReviewDate: now,
        createdAt: now,
      ),
    ];

    try {
      for (final LearningItem item in demoItems) {
        await _addLearningItemUseCase(item);
      }
      await loadItems();
    } catch (_) {
      emit(
        state.copyWith(
          status: LearningItemsStatus.failure,
          errorMessage: 'No se pudieron crear los datos de ejemplo.',
        ),
      );
    }
  }
}
