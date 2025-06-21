// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentResultAdapter extends TypeAdapter<StudentResult> {
  @override
  final int typeId = 2;

  @override
  StudentResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentResult(
      id: fields[0] as String,
      rollNumber: fields[1] as String,
      studentName: fields[2] as String?,
      answerKeyId: fields[3] as String,
      studentAnswers: (fields[4] as List).cast<String?>(),
      score: fields[5] as double,
      maxScore: fields[6] as double,
      examDate: fields[7] as DateTime,
      correctnessMap: (fields[8] as Map).cast<int, bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, StudentResult obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rollNumber)
      ..writeByte(2)
      ..write(obj.studentName)
      ..writeByte(3)
      ..write(obj.answerKeyId)
      ..writeByte(4)
      ..write(obj.studentAnswers)
      ..writeByte(5)
      ..write(obj.score)
      ..writeByte(6)
      ..write(obj.maxScore)
      ..writeByte(7)
      ..write(obj.examDate)
      ..writeByte(8)
      ..write(obj.correctnessMap);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
