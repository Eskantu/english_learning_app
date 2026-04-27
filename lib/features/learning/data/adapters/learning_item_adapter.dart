import 'package:hive/hive.dart';

import '../models/learning_item_model.dart';

class LearningItemAdapter extends TypeAdapter<LearningItemModel> {
  @override
  final int typeId = 1;

  @override
  LearningItemModel read(BinaryReader reader) {
    final int fieldCount = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return LearningItemModel(
      id: fields[0] as String,
      text: fields[1] as String,
      meaning: fields[2] as String,
      examples: (fields[3] as List).cast<String>(),
      repetitionLevel: fields[4] as int,
      nextReviewDate: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LearningItemModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.meaning)
      ..writeByte(3)
      ..write(obj.examples)
      ..writeByte(4)
      ..write(obj.repetitionLevel)
      ..writeByte(5)
      ..write(obj.nextReviewDate)
      ..writeByte(6)
      ..write(obj.createdAt);
  }
}
