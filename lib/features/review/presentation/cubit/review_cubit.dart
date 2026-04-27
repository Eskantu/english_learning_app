import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/review_quality.dart';
import '../../domain/usecases/get_due_review_items_usecase.dart';
import '../../domain/usecases/submit_review_usecase.dart';
import 'review_state.dart';

class ReviewCubit extends Cubit<ReviewState> {
  ReviewCubit({
    required GetDueReviewItemsUseCase getDueReviewItemsUseCase,
    required SubmitReviewUseCase submitReviewUseCase,
  })  : _getDueReviewItemsUseCase = getDueReviewItemsUseCase,
        _submitReviewUseCase = submitReviewUseCase,
        super(const ReviewState());

  final GetDueReviewItemsUseCase _getDueReviewItemsUseCase;
  final SubmitReviewUseCase _submitReviewUseCase;

  Future<void> loadDueItems() async {
    emit(state.copyWith(status: ReviewStatus.loading, errorMessage: null));
    try {
      final items = await _getDueReviewItemsUseCase(DateTime.now());
      if (items.isEmpty) {
        emit(state.copyWith(status: ReviewStatus.completed, items: items, currentIndex: 0));
        return;
      }
      emit(state.copyWith(status: ReviewStatus.success, items: items, currentIndex: 0));
    } catch (_) {
      emit(
        state.copyWith(
          status: ReviewStatus.failure,
          errorMessage: 'No se pudieron cargar los items de repaso.',
        ),
      );
    }
  }

  Future<void> submitAnswer(ReviewQuality quality) async {
    final currentItem = state.currentItem;
    if (currentItem == null) {
      return;
    }

    try {
      await _submitReviewUseCase(item: currentItem, quality: quality);
      final int nextIndex = state.currentIndex + 1;
      if (nextIndex >= state.items.length) {
        emit(state.copyWith(status: ReviewStatus.completed, currentIndex: nextIndex));
      } else {
        emit(state.copyWith(status: ReviewStatus.success, currentIndex: nextIndex));
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: ReviewStatus.failure,
          errorMessage: 'No se pudo guardar el resultado del repaso.',
        ),
      );
    }
  }
}
