// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_completion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyCompletionAdapter extends TypeAdapter<DailyCompletion> {
  @override
  final int typeId = 2;

  @override
  DailyCompletion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyCompletion(
      id: fields[0] as String,
      mantraId: fields[1] as String,
      date: fields[2] as DateTime,
      completed: fields[3] as bool,
      completionTime: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyCompletion obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mantraId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.completionTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyCompletionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
