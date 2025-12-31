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
      difficulty: fields[7] == null
          ? HabitDifficulty.medium
          : fields[7] as HabitDifficulty,
      category:
          fields[8] == null ? HabitCategory.other : fields[8] as HabitCategory,
      targetValue: fields[9] == null ? 1 : fields[9] as int,
      currentValue: fields[10] == null ? 0 : fields[10] as int,
      unit: fields[11] == null ? '' : fields[11] as String,
      isTimer: fields[12] == null ? false : fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.difficulty)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.targetValue)
      ..writeByte(10)
      ..write(obj.currentValue)
      ..writeByte(11)
      ..write(obj.unit)
      ..writeByte(12)
      ..write(obj.isTimer);
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

class HabitCategoryAdapter extends TypeAdapter<HabitCategory> {
  @override
  final int typeId = 2;

  @override
  HabitCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitCategory.sport;
      case 1:
        return HabitCategory.work;
      case 2:
        return HabitCategory.health;
      case 3:
        return HabitCategory.art;
      case 4:
        return HabitCategory.social;
      case 5:
        return HabitCategory.other;
      default:
        return HabitCategory.sport;
    }
  }

  @override
  void write(BinaryWriter writer, HabitCategory obj) {
    switch (obj) {
      case HabitCategory.sport:
        writer.writeByte(0);
        break;
      case HabitCategory.work:
        writer.writeByte(1);
        break;
      case HabitCategory.health:
        writer.writeByte(2);
        break;
      case HabitCategory.art:
        writer.writeByte(3);
        break;
      case HabitCategory.social:
        writer.writeByte(4);
        break;
      case HabitCategory.other:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
