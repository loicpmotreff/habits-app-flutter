// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      title: fields[1] as String,
      isCompletedToday: fields[2] as bool,
      lastCompletedDate: fields[3] as DateTime?,
      streak: fields[4] as int,
      activeDays: (fields[5] as List).cast<int>(),
      completedDays: (fields[6] as List).cast<DateTime>(),
      difficulty: fields[7] as HabitDifficulty,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isCompletedToday)
      ..writeByte(3)
      ..write(obj.lastCompletedDate)
      ..writeByte(4)
      ..write(obj.streak)
      ..writeByte(5)
      ..write(obj.activeDays)
      ..writeByte(6)
      ..write(obj.completedDays)
      ..writeByte(7)
      ..write(obj.difficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitDifficultyAdapter extends TypeAdapter<HabitDifficulty> {
  @override
  final int typeId = 1;

  @override
  HabitDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitDifficulty.easy;
      case 1:
        return HabitDifficulty.medium;
      case 2:
        return HabitDifficulty.hard;
      default:
        return HabitDifficulty.easy;
    }
  }

  @override
  void write(BinaryWriter writer, HabitDifficulty obj) {
    switch (obj) {
      case HabitDifficulty.easy:
        writer.writeByte(0);
        break;
      case HabitDifficulty.medium:
        writer.writeByte(1);
        break;
      case HabitDifficulty.hard:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
