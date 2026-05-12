import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../learning/domain/entities/learning_item.dart';
import '../cubit/pronunciation_cubit.dart';
import '../cubit/pronunciation_state.dart';
import '../widgets/pronunciation_main_view.dart';
import '../widgets/pronunciation_recording_view.dart';
import '../widgets/pronunciation_result_view.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key, required this.items});

  final List<LearningItem> items;

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

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
            if (state.status == PronunciationStatus.playing) {
              _speakerPulse.repeat(reverse: true);
            } else {
              _speakerPulse
                ..stop()
                ..reset();
            }

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
      return PronunciationRecordingView(
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
      return PronunciationResultView(
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

    return PronunciationMainView(
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
