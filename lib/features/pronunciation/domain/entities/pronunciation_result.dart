enum PronunciationFeedback {
  correct,
  almostCorrect,
  incorrect,
}

class PronunciationResult {
  const PronunciationResult({
    required this.score,
    required this.feedback,
  });

  final double score;
  final PronunciationFeedback feedback;
}
