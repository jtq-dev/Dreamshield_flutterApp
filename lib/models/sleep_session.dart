class SleepSession {
  final String id;
  final DateTime start;
  final DateTime end;
  final int comfortRating; // 1-5
  final int noiseLevel; // 1-5
  final double? lat;
  final double? lng;
  final String notes;
  final String? preset;

  SleepSession({
    required this.id,
    required this.start,
    required this.end,
    required this.comfortRating,
    required this.noiseLevel,
    this.lat,
    this.lng,
    this.notes = '',
    this.preset,
  });

  double get durationHours => end.difference(start).inMinutes / 60.0;
}
