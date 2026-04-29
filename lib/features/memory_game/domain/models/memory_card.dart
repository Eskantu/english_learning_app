import 'package:equatable/equatable.dart';

enum MemoryCardType { base, meaning }

class MemoryCard extends Equatable {
  const MemoryCard({
    required this.id,
    required this.value,
    required this.pairId,
    required this.type,
    this.isFlipped = false,
    this.isMatched = false,
  });

  final String id;
  final String value;
  final String pairId;
  final MemoryCardType type;
  final bool isFlipped;
  final bool isMatched;

  MemoryCard copyWith({
    String? id,
    String? value,
    String? pairId,
    MemoryCardType? type,
    bool? isFlipped,
    bool? isMatched,
  }) {
    return MemoryCard(
      id: id ?? this.id,
      value: value ?? this.value,
      pairId: pairId ?? this.pairId,
      type: type ?? this.type,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    value,
    pairId,
    type,
    isFlipped,
    isMatched,
  ];
}
