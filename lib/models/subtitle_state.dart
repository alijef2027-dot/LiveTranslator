/// Status of the live translation pipeline.
enum TranslationStatus {
  idle,
  loadingModel,
  ready,
  listening,
  error,
}

/// A single confirmed or provisional subtitle segment.
class SubtitleSegment {
  final String english;
  final String arabic;
  final bool isProvisional;
  final DateTime timestamp;

  const SubtitleSegment({
    required this.english,
    required this.arabic,
    required this.isProvisional,
    required this.timestamp,
  });

  SubtitleSegment copyWith({
    String? english,
    String? arabic,
    bool? isProvisional,
    DateTime? timestamp,
  }) {
    return SubtitleSegment(
      english: english ?? this.english,
      arabic: arabic ?? this.arabic,
      isProvisional: isProvisional ?? this.isProvisional,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
