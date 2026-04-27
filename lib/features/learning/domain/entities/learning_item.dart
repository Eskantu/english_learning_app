import 'package:equatable/equatable.dart';

class LearningItem extends Equatable {
  const LearningItem({
    required this.id,
    required this.text,
    required this.meaning,
    required this.examples,
    required this.repetitionLevel,
    required this.nextReviewDate,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String meaning;
  final List<String> examples;
  final int repetitionLevel;
  final DateTime nextReviewDate;
  final DateTime createdAt;

  LearningItem copyWith({
    String? id,
    String? text,
    String? meaning,
    List<String>? examples,
    int? repetitionLevel,
    DateTime? nextReviewDate,
    DateTime? createdAt,
  }) {
    return LearningItem(
      id: id ?? this.id,
      text: text ?? this.text,
      meaning: meaning ?? this.meaning,
      examples: examples ?? this.examples,
      repetitionLevel: repetitionLevel ?? this.repetitionLevel,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        text,
        meaning,
        examples,
        repetitionLevel,
        nextReviewDate,
        createdAt,
      ];
}
