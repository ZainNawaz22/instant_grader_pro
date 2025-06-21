// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_key.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnswerKeyAdapter extends TypeAdapter<AnswerKey> {
  @override
  final int typeId = 1;

  @override
  AnswerKey read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnswerKey(
      id: fields[0] as String,
      testName: fields[1] as String,
      correctAnswers: (fields[2] as List).cast<String>(),
      totalQuestions: fields[3] as int,
      marksPerQuestion: fields[4] as double,
      createdAt: fields[5] as DateTime,
      subject: fields[6] as String?,
      className: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AnswerKey obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.testName)
      ..writeByte(2)
      ..write(obj.correctAnswers)
      ..writeByte(3)
      ..write(obj.totalQuestions)
      ..writeByte(4)
      ..write(obj.marksPerQuestion)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.subject)
      ..writeByte(7)
      ..write(obj.className);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerKeyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
