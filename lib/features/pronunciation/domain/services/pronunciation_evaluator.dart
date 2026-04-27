import '../entities/pronunciation_result.dart';

class PronunciationEvaluator {
  PronunciationResult evaluate({
    required String expected,
    required String spoken,
  }) {
    final String normalizedExpected = _normalize(expected);
    final String normalizedSpoken = _normalize(spoken);

    if (normalizedExpected.isEmpty || normalizedSpoken.isEmpty) {
      return const PronunciationResult(
        score: 0,
        feedback: PronunciationFeedback.incorrect,
      );
    }

    final int distance = _levenshtein(normalizedExpected, normalizedSpoken);
    final int maxLength = normalizedExpected.length > normalizedSpoken.length
        ? normalizedExpected.length
        : normalizedSpoken.length;
    final double similarity = 1 - (distance / maxLength);

    if (similarity >= 0.9) {
      return PronunciationResult(
        score: similarity,
        feedback: PronunciationFeedback.correct,
      );
    }
    if (similarity >= 0.7) {
      return PronunciationResult(
        score: similarity,
        feedback: PronunciationFeedback.almostCorrect,
      );
    }
    return PronunciationResult(
      score: similarity,
      feedback: PronunciationFeedback.incorrect,
    );
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _levenshtein(String s1, String s2) {
    final List<List<int>> matrix = List<List<int>>.generate(
      s1.length + 1,
      (int i) => List<int>.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = <int>[
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((int a, int b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }
}
