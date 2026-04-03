import '../../domain/entities/availability_slot_entity.dart';

class AvailabilitySlotModel extends AvailabilitySlotEntity {
  const AvailabilitySlotModel({
    required super.id,
    required super.professionalId,
    required super.dayOfWeek,
    required super.startTime,
    required super.endTime,
    required super.slotDuration,
    required super.isAvailable,
  });

  factory AvailabilitySlotModel.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlotModel(
      id: json['id'].toString(),
      professionalId: (json['professional'] ?? '').toString(),
      dayOfWeek: int.tryParse((json['day_of_week'] ?? 0).toString()) ?? 0,
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      slotDuration:
          int.tryParse((json['slot_duration'] ?? json['slotDuration'] ?? 30).toString()) ?? 30,
      isAvailable: (json['is_available'] ?? json['isAvailable'] ?? true) == true,
    );
  }
}
