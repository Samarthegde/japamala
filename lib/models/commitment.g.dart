// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommitmentAdapter extends TypeAdapter<Commitment> {
  @override
  final int typeId = 4;

  @override
  Commitment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Commitment(
      id: fields[0] as String,
      mantraId: fields[1] as String,
      targetCount: fields[2] as int,
      startDate: fields[3] as DateTime,
      createdAt: fields[5] as DateTime,
      deadline: fields[4] as DateTime?,
      completedAt: fields[6] as DateTime?,
      intention: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Commitment obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mantraId)
      ..writeByte(2)
      ..write(obj.targetCount)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.deadline)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.intention);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
