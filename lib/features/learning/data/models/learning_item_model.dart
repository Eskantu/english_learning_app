import '../../domain/entities/learning_item.dart';

class LearningItemModel extends LearningItem {
  const LearningItemModel({
    required super.id,
    required super.text,
    required super.meaning,
    required super.examples,
    required super.repetitionLevel,
    required super.nextReviewDate,
    required super.createdAt,
  });

  factory LearningItemModel.fromEntity(LearningItem item) {
    return LearningItemModel(
      id: item.id,
      text: item.text,
      meaning: item.meaning,
      examples: item.examples,
      repetitionLevel: item.repetitionLevel,
      nextReviewDate: item.nextReviewDate,
      createdAt: item.createdAt,
    );
  }

  factory LearningItemModel.fromMap(Map<dynamic, dynamic> map) {
    return LearningItemModel(
      id: map['id'] as String,
      text: map['text'] as String,
      meaning: map['meaning'] as String,
      examples: (map['examples'] as List<dynamic>).cast<String>(),
      repetitionLevel: map['repetitionLevel'] as int,
      nextReviewDate: DateTime.parse(map['nextReviewDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'meaning': meaning,
      'examples': examples,
      'repetitionLevel': repetitionLevel,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
