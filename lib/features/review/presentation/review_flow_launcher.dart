import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../learning/presentation/cubit/learning_items_cubit.dart';
import 'cubit/review_cubit.dart';
import 'screens/review_screen.dart';

class ReviewFlowLauncher {
  const ReviewFlowLauncher._();

  static Future<void> openReview(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: <BlocProvider>[
            BlocProvider.value(value: context.read<LearningItemsCubit>()),
            BlocProvider<ReviewCubit>(
              create: (_) => ReviewCubit(
                getDueReviewItemsUseCase: ServiceLocator.getDueReviewItemsUseCase,
                submitReviewUseCase: ServiceLocator.submitReviewUseCase,
              )..loadDueItems(),
            ),
          ],
          child: const ReviewScreen(),
        ),
      ),
    );
  }
}
