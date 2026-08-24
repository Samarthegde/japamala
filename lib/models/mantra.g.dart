// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mantra.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MantraAdapter extends TypeAdapter<Mantra> {
  @override
  final int typeId = 0;

  @override
  Mantra read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mantra(
      id: fields[0] as String,
      name: fields[1] as String,
      targetCount: fields[2] as int,
      description: fields[3] as String?,
      createdDate: fields[4] as DateTime,
      currentCount: fields[5] as int,
      isDaily: fields[6] as bool,
      lastResetDate: fields[7] as DateTime?,
      beadsPerRound: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Mantra obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetCount)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.createdDate)
      ..writeByte(5)
      ..write(obj.currentCount)
      ..writeByte(6)
      ..write(obj.isDaily)
      ..writeByte(7)
      ..write(obj.lastResetDate)
      ..writeByte(8)
      ..write(obj.beadsPerRound);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MantraAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
