class AvailabilitySlotEntity {
  const AvailabilitySlotEntity({
    required this.id,
    required this.professionalId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotDuration,
    required this.isAvailable,
  });

  final String id;
  final String professionalId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int slotDuration;
  final bool isAvailable;
}
