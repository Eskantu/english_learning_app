import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../learning/domain/entities/learning_item.dart';
import '../cubit/pronunciation_cubit.dart';
import '../cubit/pronunciation_state.dart';
import '../../domain/entities/pronunciation_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Full pronunciation practice flow.
///
/// **Visual states**
/// - [PronunciationStatus.initial] / [PronunciationStatus.playing] /
///   [PronunciationStatus.failure] → [_MainView]
/// - [PronunciationStatus.listening] → [_RecordingView]
/// - [PronunciationStatus.result]    → [_ResultView]
class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key, required this.items});

  final List<LearningItem> items;

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen>
    with TickerProviderStateMixin {
  /// Which phrase the user is currently practising.
  int _currentIndex = 0;

  // Animation controllers – started/stopped via BlocConsumer listener.
  late final AnimationController _speakerPulse;
  late final AnimationController _micPulse;
  late final AnimationController _waveformController;

  int _recordSeconds = 0;
  Timer? _recordTimer;

  LearningItem get _currentItem => widget.items[_currentIndex];

  @override
  void initState() {
    super.initState();
    _speakerPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.items.isNotEmpty) {
      context.read<PronunciationCubit>().selectItem(_currentItem);
    }
  }

  @override
  void dispose() {
    _speakerPulse.dispose();
    _micPulse.dispose();
    _waveformController.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _startRecordTimer() {
    _recordSeconds = 0;
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
  }

  void _goToNextPhrase() {
    if (_currentIndex < widget.items.length - 1) {
      setState(() => _currentIndex++);
      context.read<PronunciationCubit>().selectItem(_currentItem);
    } else {
      Navigator.of(context).pop();
    }
  }

  String get _formattedTime {
    final int m = _recordSeconds ~/ 60;
    final int s = _recordSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pronunciacion')),
        body: const Center(child: Text('No hay frases para practicar.')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: BlocConsumer<PronunciationCubit, PronunciationState>(
          listener: (BuildContext context, PronunciationState state) {
            // Speaker pulse: active only while TTS is playing.
            if (state.status == PronunciationStatus.playing) {
              _speakerPulse.repeat(reverse: true);
            } else {
              _speakerPulse
                ..stop()
                ..reset();
            }
            // Mic + waveform: active only while STT is listening.
            if (state.status == PronunciationStatus.listening) {
              _micPulse.repeat(reverse: true);
              _waveformController.repeat();
              _startRecordTimer();
            } else {
              _micPulse
                ..stop()
                ..reset();
              _waveformController
                ..stop()
                ..reset();
              _stopRecordTimer();
            }
          },
          builder: (BuildContext context, PronunciationState state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PronunciationState state) {
    if (state.status == PronunciationStatus.listening) {
      return _RecordingView(
        key: const ValueKey<String>('recording'),
        micPulse: _micPulse,
        waveformController: _waveformController,
        elapsed: _formattedTime,
        currentIndex: _currentIndex,
        total: widget.items.length,
        onCancel: () => context.read<PronunciationCubit>().cancelRecording(),
      );
    }

    if (state.status == PronunciationStatus.result && state.result != null) {
      return _ResultView(
        key: const ValueKey<String>('result'),
        recognizedText: state.recognizedText ?? '',
        originalPhrase: _currentItem.text,
        result: state.result!,
        currentIndex: _currentIndex,
        total: widget.items.length,
        isLastPhrase: _currentIndex >= widget.items.length - 1,
        onRetry: () => context.read<PronunciationCubit>().captureAndEvaluate(),
        onNext: _goToNextPhrase,
      );
    }

    return _MainView(
      key: const ValueKey<String>('main'),
      items: widget.items,
      currentIndex: _currentIndex,
      state: state,
      speakerPulse: _speakerPulse,
      onSelectItem: (LearningItem item) {
        final int idx = widget.items.indexOf(item);
        if (idx >= 0) setState(() => _currentIndex = idx);
        context.read<PronunciationCubit>().selectItem(item);
      },
      onSpeak: () => context.read<PronunciationCubit>().speakSelectedText(),
      onRecord: () => context.read<PronunciationCubit>().captureAndEvaluate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view (idle / playing / failure)
// ─────────────────────────────────────────────────────────────────────────────

class _MainView extends StatelessWidget {
  const _MainView({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.state,
    required this.speakerPulse,
    required this.onSelectItem,
    required this.onSpeak,
    required this.onRecord,
  });

  final List<LearningItem> items;
  final int currentIndex;
  final PronunciationState state;
  final AnimationController speakerPulse;
  final ValueChanged<LearningItem> onSelectItem;
  final VoidCallback onSpeak;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 700;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ScreenHeader(
                    title: 'Pronunciación',
                    currentIndex: currentIndex,
                    total: items.length,
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  // Phrase selector label.
                  Text(
                    'Frase a practicar',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PhraseSelectorWidget(
                    items: items,
                    selected: items[currentIndex],
                    onChanged: (LearningItem? v) {
                      if (v != null) onSelectItem(v);
                    },
                  ),
                  SizedBox(height: compact ? 14 : 20),
                  PronunciationCard(
                    phrase: state.selectedItem?.text ?? '',
                    speakerPulse: speakerPulse,
                    compact: compact,
                    onSpeak: onSpeak,
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  _HintCard(compact: compact),
                  if (state.status == PronunciationStatus.failure)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        state.errorMessage ?? 'Ocurrió un error.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  SizedBox(height: compact ? 16 : 24),
                  _ActionButton(
                    label: 'Escuchar frase (TTS)',
                    icon: Icons.volume_up_rounded,
                    onPressed: onSpeak,
                    loading: state.status == PronunciationStatus.playing,
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    label: 'Grabar y evaluar (STT)',
                    icon: Icons.mic_rounded,
                    onPressed: onRecord,
                    color: AppColors.secondaryDark,
                  ),
                  SizedBox(height: compact ? 14 : 20),
                  _ConsejoCard(compact: compact),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recording view
// ─────────────────────────────────────────────────────────────────────────────

class _RecordingView extends StatelessWidget {
  const _RecordingView({
    super.key,
    required this.micPulse,
    required this.waveformController,
    required this.elapsed,
    required this.currentIndex,
    required this.total,
    required this.onCancel,
  });

  final AnimationController micPulse;
  final AnimationController waveformController;
  final String elapsed;
  final int currentIndex;
  final int total;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ScreenHeader(
            title: 'Pronunciación',
            currentIndex: currentIndex,
            total: total,
          ),
          const SizedBox(height: 20),
          // Recording card.
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              children: <Widget>[
                Text(
                  'Graba tu pronunciación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Habla ahora...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                // Waveform + mic row.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _WaveformWidget(
                      controller: waveformController,
                      barCount: 5,
                      phaseOffset: 0,
                    ),
                    const SizedBox(width: 16),
                    RecordingWidget(micPulse: micPulse),
                    const SizedBox(width: 16),
                    _WaveformWidget(
                      controller: waveformController,
                      barCount: 5,
                      phaseOffset: math.pi,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  elapsed,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu grabación se convertirá en texto\ny se comparará con la frase correcta.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tip row.
          Row(
            children: <Widget>[
              Icon(
                Icons.graphic_eq_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Habla claro y a un ritmo natural',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Cancel button.
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar grabación'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result view
// ─────────────────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.recognizedText,
    required this.originalPhrase,
    required this.result,
    required this.currentIndex,
    required this.total,
    required this.isLastPhrase,
    required this.onRetry,
    required this.onNext,
  });

  final String recognizedText;
  final String originalPhrase;
  final PronunciationResult result;
  final int currentIndex;
  final int total;
  final bool isLastPhrase;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 700;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ScreenHeader(
                    title: 'Pronunciación',
                    currentIndex: currentIndex,
                    total: total,
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  ResultWidget(
                    recognizedText: recognizedText,
                    originalPhrase: originalPhrase,
                    result: result,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Volver a intentar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    iconAlignment: IconAlignment.end,
                    label: Text(isLastPhrase ? 'Finalizar' : 'Siguiente frase'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets (public for testing)
// ─────────────────────────────────────────────────────────────────────────────

/// Header row: back button + title + progress bar + "N de M" label.
class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.title,
    required this.currentIndex,
    required this.total,
  });

  final String title;
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : (currentIndex + 1) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.bar_chart_rounded),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${currentIndex + 1} de $total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Rounded dropdown selector showing the list of available phrases.
class PhraseSelectorWidget extends StatelessWidget {
  const PhraseSelectorWidget({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<LearningItem> items;
  final LearningItem? selected;
  final ValueChanged<LearningItem?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LearningItem>(
          value: selected,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          items: items
              .map(
                (LearningItem item) => DropdownMenuItem<LearningItem>(
                  value: item,
                  child: Text(item.text, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Large gradient card with animated speaker icon and phrase text.
class PronunciationCard extends StatelessWidget {
  const PronunciationCard({
    super.key,
    required this.phrase,
    required this.speakerPulse,
    required this.compact,
    required this.onSpeak,
  });

  final String phrase;
  final AnimationController speakerPulse;
  final bool compact;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            AppColors.primaryContainer,
            AppColors.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? 20 : 28),
      child: Column(
        children: <Widget>[
          // Speaker icon – scales with animation when TTS is playing.
          AnimatedBuilder(
            animation: speakerPulse,
            builder: (BuildContext context, Widget? child) {
              return Transform.scale(
                scale: 1.0 + 0.12 * speakerPulse.value,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: onSpeak,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.22),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.secondaryDark,
                  size: 28,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            phrase,
            textAlign: TextAlign.center,
            style: (compact
                    ? Theme.of(context).textTheme.headlineLarge
                    : Theme.of(context).textTheme.displaySmall)
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '¿Cómo suena esta frase?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing mic button used inside [_RecordingView].
class RecordingWidget extends StatelessWidget {
  const RecordingWidget({super.key, required this.micPulse});

  final AnimationController micPulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: micPulse,
      builder: (BuildContext context, Widget? child) {
        final double scale = 1.0 + 0.20 * micPulse.value;
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.scale(
              scale: scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.secondaryDark,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.22),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.mic_rounded,
          color: Theme.of(context).colorScheme.onSecondary,
          size: 38,
        ),
      ),
    );
  }
}

/// Animated equalizer-style waveform bars.
class _WaveformWidget extends StatelessWidget {
  const _WaveformWidget({
    required this.controller,
    required this.barCount,
    required this.phaseOffset,
  });

  final AnimationController controller;
  final int barCount;
  final double phaseOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List<Widget>.generate(barCount, (int i) {
            final double phase = phaseOffset + (i / barCount) * math.pi * 2;
            final double value =
                (math.sin(controller.value * math.pi * 2 + phase) + 1) / 2;
            final double height = 12 + value * 28;
            return Container(
              width: 4,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Full result card: score circle, comparison rows, feedback badge.
class ResultWidget extends StatelessWidget {
  const ResultWidget({
    super.key,
    required this.recognizedText,
    required this.originalPhrase,
    required this.result,
    required this.compact,
  });

  final String recognizedText;
  final String originalPhrase;
  final PronunciationResult result;
  final bool compact;

  Color get _scoreColor => switch (result.feedback) {
    PronunciationFeedback.correct => AppColors.success,
    PronunciationFeedback.almostCorrect => AppColors.warning,
    PronunciationFeedback.incorrect => AppColors.error,
  };

  String get _headline => switch (result.feedback) {
    PronunciationFeedback.correct => '¡Buen trabajo!',
    PronunciationFeedback.almostCorrect => '¡Casi!',
    PronunciationFeedback.incorrect => 'Inténtalo de nuevo',
  };

  String get _badgeLabel => switch (result.feedback) {
    PronunciationFeedback.correct => 'Muy bien',
    PronunciationFeedback.almostCorrect => 'Casi correcto',
    PronunciationFeedback.incorrect => 'Sigue practicando',
  };

  String get _badgeSubtitle => switch (result.feedback) {
    PronunciationFeedback.correct => 'Tu pronunciación es muy similar.',
    PronunciationFeedback.almostCorrect => 'Sigue practicando un poco más.',
    PronunciationFeedback.incorrect =>
      'La pronunciación necesita más práctica.',
  };

  IconData get _badgeIcon => switch (result.feedback) {
    PronunciationFeedback.correct => Icons.check_circle_rounded,
    PronunciationFeedback.almostCorrect => Icons.remove_circle_outline_rounded,
    PronunciationFeedback.incorrect => Icons.cancel_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final int scoreInt = (result.score * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _scoreColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.all(compact ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Resultado',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: compact ? 16 : 22),
          // Score circle.
          Center(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: result.score,
                      strokeWidth: 9,
                      color: _scoreColor,
                      backgroundColor: _scoreColor.withValues(alpha: 0.15),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$scoreInt',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _scoreColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _headline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          // "Tu dijiste" row.
          _ResultRow(
            label: 'Tu dijiste:',
            text: recognizedText,
            highlight: true,
            color: _scoreColor,
          ),
          const SizedBox(height: 10),
          // "Frase correcta" row.
          _ResultRow(label: 'Frase correcta:', text: originalPhrase),
          SizedBox(height: compact ? 14 : 18),
          // Feedback badge.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _scoreColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                Icon(_badgeIcon, color: _scoreColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _badgeLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _scoreColor,
                        ),
                      ),
                      Text(
                        _badgeSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.text,
    this.highlight = false,
    this.color,
  });

  final String label;
  final String text;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                highlight && color != null
                    ? color!.withValues(alpha: 0.10)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  highlight && color != null
                      ? color!
                      : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HintCard extends StatelessWidget {
  const _HintCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Row(
        children: <Widget>[
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Escucha la frase primero y luego repítela lo mejor posible.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary/secondary action button used on the main view.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon:
          loading
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surfaceContainerHighest,
                ),
              )
              : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        disabledBackgroundColor: (color ??
                Theme.of(context).colorScheme.primary)
            .withValues(alpha: 0.6),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// Advice card shown at the bottom of the main view.
class _ConsejoCard extends StatelessWidget {
  const _ConsejoCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.star_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Consejo',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Habla claro, a un ritmo natural y sin prisa.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text('🎧', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}
