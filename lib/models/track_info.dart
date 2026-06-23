/// Track metadata for a media item (GET /track-info). The desktop serialises
/// these structs without explicit json tags, so the keys are PascalCase.
class VideoTrack {
  final int index;
  final String codecs;
  final String resolution;

  const VideoTrack({required this.index, this.codecs = '', this.resolution = ''});

  factory VideoTrack.fromJson(Map<String, dynamic> j) => VideoTrack(
        index: j['Index'] as int? ?? 0,
        codecs: j['Codecs'] as String? ?? '',
        resolution: j['Resolution'] as String? ?? '',
      );

  String get label {
    final parts = [
      if (resolution.isNotEmpty) resolution,
      if (codecs.isNotEmpty) codecs,
    ];
    final desc = parts.join(' · ');
    return desc.isEmpty ? 'Video $index' : 'Video $index ($desc)';
  }
}

class AudioTrack {
  final int index;
  final String language;

  const AudioTrack({required this.index, this.language = ''});

  factory AudioTrack.fromJson(Map<String, dynamic> j) => AudioTrack(
        index: j['Index'] as int? ?? 0,
        language: j['Language'] as String? ?? '',
      );

  String get label =>
      language.isEmpty ? 'Audio $index' : 'Audio $index (${language.trim()})';
}

class SubtitleTrack {
  final String path;
  final String label;

  const SubtitleTrack({required this.path, required this.label});

  factory SubtitleTrack.fromJson(Map<String, dynamic> j) => SubtitleTrack(
        path: j['Path'] as String? ?? 'none',
        label: j['Label'] as String? ?? 'None',
      );
}

class TrackInfo {
  final List<VideoTrack> videoTracks;
  final List<AudioTrack> audioTracks;
  final List<SubtitleTrack> subtitleTracks;
  final String path;
  final String nearSubtitle;

  const TrackInfo({
    this.videoTracks = const [],
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.path = '',
    this.nearSubtitle = '',
  });

  factory TrackInfo.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        (j[key] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(f)
            .toList();
    return TrackInfo(
      videoTracks: list('VideoTracks', VideoTrack.fromJson),
      audioTracks: list('AudioTracks', AudioTrack.fromJson),
      subtitleTracks: list('SubtitleTracks', SubtitleTrack.fromJson),
      path: j['Path'] as String? ?? '',
      nearSubtitle: j['NearSubtitle'] as String? ?? '',
    );
  }
}

/// A quality preset from GET /settings.qualityOptions.
class QualityOption {
  final String value;
  final String label;
  const QualityOption({required this.value, required this.label});

  factory QualityOption.fromJson(Map<String, dynamic> j) => QualityOption(
        value: j['value'] as String? ?? '',
        label: j['label'] as String? ?? '',
      );
}

/// The remote-relevant subset of desktop settings (GET/POST /settings).
class RemoteSettings {
  final int subtitleFontSize;
  final bool subtitleBurnIn;
  final bool ignoreClosedCaptions;
  final String defaultQuality;
  final String defaultTranslationLanguage;

  const RemoteSettings({
    this.subtitleFontSize = 24,
    this.subtitleBurnIn = true,
    this.ignoreClosedCaptions = false,
    this.defaultQuality = '5M',
    this.defaultTranslationLanguage = 'English',
  });

  factory RemoteSettings.fromJson(Map<String, dynamic> j) => RemoteSettings(
        subtitleFontSize: j['subtitleFontSize'] as int? ?? 24,
        subtitleBurnIn: j['subtitleBurnIn'] as bool? ?? true,
        ignoreClosedCaptions: j['ignoreClosedCaptions'] as bool? ?? false,
        defaultQuality: j['defaultQuality'] as String? ?? '5M',
        defaultTranslationLanguage:
            j['defaultTranslationLanguage'] as String? ?? 'English',
      );

  Map<String, dynamic> toJson() => {
        'subtitleFontSize': subtitleFontSize,
        'subtitleBurnIn': subtitleBurnIn,
        'ignoreClosedCaptions': ignoreClosedCaptions,
        'defaultQuality': defaultQuality,
        'defaultTranslationLanguage': defaultTranslationLanguage,
      };

  RemoteSettings copyWith({
    int? subtitleFontSize,
    bool? subtitleBurnIn,
    bool? ignoreClosedCaptions,
    String? defaultQuality,
    String? defaultTranslationLanguage,
  }) =>
      RemoteSettings(
        subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
        subtitleBurnIn: subtitleBurnIn ?? this.subtitleBurnIn,
        ignoreClosedCaptions: ignoreClosedCaptions ?? this.ignoreClosedCaptions,
        defaultQuality: defaultQuality ?? this.defaultQuality,
        defaultTranslationLanguage:
            defaultTranslationLanguage ?? this.defaultTranslationLanguage,
      );
}

/// Result of GET /translate-status.
class TranslateStatus {
  final bool inProgress;
  final String language;
  final List<String> files;
  final String error;

  const TranslateStatus({
    this.inProgress = false,
    this.language = '',
    this.files = const [],
    this.error = '',
  });

  factory TranslateStatus.fromJson(Map<String, dynamic> j) => TranslateStatus(
        inProgress: j['inProgress'] as bool? ?? false,
        language: j['language'] as String? ?? '',
        files: (j['files'] as List<dynamic>? ?? []).cast<String>(),
        error: j['error'] as String? ?? '',
      );
}
