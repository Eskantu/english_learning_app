import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/learning/presentation/presentation.dart';
import 'presentation/splash/voxly_splash_screen.dart';
import 'features/review/presentation/presentation.dart';

/// Application entry point.
///
/// Bootstraps platform bindings and dependency graph before rendering the UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.init();
  runApp(const EnglishLearningApp());
}

/// Root widget that wires navigation and notification deep-link handling.
class EnglishLearningApp extends StatefulWidget {
  const EnglishLearningApp({super.key});

  @override
  State<EnglishLearningApp> createState() => _EnglishLearningAppState();
}

class _EnglishLearningAppState extends State<EnglishLearningApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Handle taps while the app is alive (foreground/background resume).
    ServiceLocator.notificationService.onNotificationTap.listen(_handlePayload);

    // Handle cold-start launches from a notification payload.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String? launchPayload = await ServiceLocator.notificationService.getLaunchPayload();
      if (launchPayload != null) {
        _handlePayload(launchPayload);
      }
    });
  }

  void _handlePayload(String payload) {
    // Keep payload routing explicit so unsupported payloads are ignored safely.
    if (payload != 'open_review') {
      return;
    }
    final BuildContext? context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    ReviewFlowLauncher.openReview(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LearningItemsCubit>(
      create: (_) => LearningItemsCubit(
        getAllLearningItemsUseCase: ServiceLocator.getAllLearningItemsUseCase,
        addLearningItemUseCase: ServiceLocator.addLearningItemUseCase,
        updateLearningItemUseCase: ServiceLocator.updateLearningItemUseCase,
        deleteLearningItemUseCase: ServiceLocator.deleteLearningItemUseCase,
        getItemsToReviewUseCase: ServiceLocator.getItemsToReviewUseCase,
        notificationService: ServiceLocator.notificationService,
      )..loadItems(),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const VoxlySplashScreen(),
      ),
    );
  }
}
