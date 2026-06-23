class LibraryItem {
  final String id;
  final String name;
  final String path;
  final int? duration;

  const LibraryItem({
    required this.id,
    required this.name,
    required this.path,
    this.duration,
  });

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String? ?? '',
      duration: json['duration'] as int?,
    );
  }

  String get durationFormatted {
    if (duration == null || duration == 0) return '';
    final h = duration! ~/ 3600;
    final m = (duration! % 3600) ~/ 60;
    final s = duration! % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '$m:${s.toString().padLeft(2,'0')}';
  }
}
