/// Mirror of the desktop's PlaybackState (GET /state).
class PlaybackState {
  final String status; // "", "PLAYING", "PAUSED", "STOPPED"
  final String mediaPath;
  final String mediaName;
  final String deviceUrl;
  final String deviceName;
  final double currentTime;
  final double duration;
  final double volume;
  final bool muted;

  const PlaybackState({
    this.status = '',
    this.mediaPath = '',
    this.mediaName = '',
    this.deviceUrl = '',
    this.deviceName = '',
    this.currentTime = 0,
    this.duration = 0,
    this.volume = 0,
    this.muted = false,
  });

  bool get isPlaying => status == 'PLAYING';
  bool get isPaused => status == 'PAUSED';

  /// Whether there is something loaded worth showing a now-playing bar for.
  bool get isActive =>
      mediaName.isNotEmpty && status != 'STOPPED';

  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0;
    return PlaybackState(
      status: json['status'] as String? ?? '',
      mediaPath: json['mediaPath'] as String? ?? '',
      mediaName: json['mediaName'] as String? ?? '',
      deviceUrl: json['deviceUrl'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      currentTime: d(json['currentTime']),
      duration: d(json['duration']),
      volume: d(json['volume']),
      muted: json['muted'] as bool? ?? false,
    );
  }

  static String formatTime(double seconds) {
    if (seconds.isNaN || seconds < 0) seconds = 0;
    final total = seconds.round();
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }
}
