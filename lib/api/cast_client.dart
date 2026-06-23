import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cast_device.dart';
import '../models/library_item.dart';
import '../models/playback_state.dart';
import '../models/track_info.dart';

class CastApiException implements Exception {
  final String message;
  final int? statusCode;
  CastApiException(this.message, {this.statusCode});
  @override
  String toString() => 'CastApiException: $message';
}

/// Options for a play request: track/subtitle/quality selection.
class PlayOptions {
  final int videoTrack;
  final int audioTrack;
  final String subtitlePath; // "none" or a subtitle path
  /// null = use desktop's default quality; "" = Original; e.g. "5M".
  final String? quality;

  const PlayOptions({
    this.videoTrack = 0,
    this.audioTrack = 0,
    this.subtitlePath = 'none',
    this.quality,
  });

  Map<String, dynamic> toJson() => {
        'videoTrack': videoTrack,
        'audioTrack': audioTrack,
        'subtitlePath': subtitlePath,
        if (quality != null) 'quality': quality,
      };
}

class CastClient {
  final String host;
  final int port;
  final String? token;
  final Duration timeout;

  CastClient({
    required this.host,
    required this.port,
    this.token,
    this.timeout = const Duration(seconds: 10),
  });

  String get baseUrl => 'http://$host:$port';

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      h['X-Cast-Token'] = token!;
    }
    return h;
  }

  Future<Map<String, dynamic>> _get(String path, {Duration? timeout}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response =
        await http.get(uri, headers: _headers).timeout(timeout ?? this.timeout);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(timeout);
    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 401) {
      throw CastApiException('Unauthorized: invalid or missing token',
          statusCode: 401);
    }
    if (response.statusCode >= 400) {
      throw CastApiException(
        data['error'] as String? ?? 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  Future<bool> ping() async {
    final data = await _get('/ping');
    return data['ok'] == true;
  }

  Future<List<LibraryItem>> getLibrary() async {
    final data = await _get('/library');
    final items = data['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>().map(LibraryItem.fromJson).toList();
  }

  /// Discovery on the desktop can take a couple of seconds, hence the longer
  /// timeout.
  Future<List<CastDevice>> getDevices() async {
    final data = await _get('/devices', timeout: const Duration(seconds: 12));
    final items = data['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>().map(CastDevice.fromJson).toList();
  }

  Future<PlaybackState> getState() async {
    final data = await _get('/state', timeout: const Duration(seconds: 5));
    return PlaybackState.fromJson(data);
  }

  Future<TrackInfo> getTrackInfo(String id) async {
    final data = await _get('/track-info?id=${Uri.encodeQueryComponent(id)}',
        timeout: const Duration(seconds: 20));
    return TrackInfo.fromJson(data);
  }

  Future<void> playItem(String id,
      {String deviceIp = 'local', PlayOptions? options}) async {
    final result = await _post('/play', {
      'id': id,
      'deviceIp': deviceIp,
      ...?options?.toJson(),
    });
    if (result['ok'] != true) {
      throw CastApiException(result['error'] as String? ?? 'Play failed');
    }
  }

  Future<void> playUrl(String url,
      {String deviceIp = 'local', PlayOptions? options}) async {
    final result = await _post('/play-url', {
      'url': url,
      'deviceIp': deviceIp,
      ...?options?.toJson(),
    });
    if (result['ok'] != true) {
      throw CastApiException(result['error'] as String? ?? 'Play URL failed');
    }
  }

  Future<PlaybackState> control(String action, {double? value}) async {
    final result = await _post('/control', {
      'action': action,
      if (value != null) 'value': value,
    });
    if (result['ok'] != true) {
      throw CastApiException(result['error'] as String? ?? 'Control failed');
    }
    return PlaybackState.fromJson(result['state'] as Map<String, dynamic>);
  }

  Future<void> pause() => control('pause');
  Future<void> resume() => control('resume');
  Future<void> stop() => control('stop');
  Future<void> seek(double seconds) => control('seek', value: seconds);
  Future<void> setVolume(double level) => control('volume', value: level);
  Future<void> setMuted(bool muted) => control(muted ? 'mute' : 'unmute');

  Future<String> translate(String id, {String? language}) async {
    final result = await _post('/translate', {
      'id': id,
      if (language != null) 'language': language,
    });
    if (result['ok'] != true) {
      throw CastApiException(result['error'] as String? ?? 'Translate failed');
    }
    return result['language'] as String? ?? (language ?? '');
  }

  Future<({bool translated, String language, String subtitlePath})>
      getTranslationInfo(String id, {String? language}) async {
    final q = StringBuffer('/translation-info?id=${Uri.encodeQueryComponent(id)}');
    if (language != null && language.isNotEmpty) {
      q.write('&language=${Uri.encodeQueryComponent(language)}');
    }
    final data = await _get(q.toString(), timeout: const Duration(seconds: 5));
    return (
      translated: data['translated'] as bool? ?? false,
      language: data['language'] as String? ?? '',
      subtitlePath: data['subtitlePath'] as String? ?? '',
    );
  }

  Future<TranslateStatus> getTranslateStatus() async {
    final data =
        await _get('/translate-status', timeout: const Duration(seconds: 5));
    return TranslateStatus.fromJson(data);
  }

  Future<({RemoteSettings settings, List<QualityOption> qualityOptions})>
      getSettings() async {
    final data = await _get('/settings');
    final settings =
        RemoteSettings.fromJson(data['settings'] as Map<String, dynamic>? ?? {});
    final quality = (data['qualityOptions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(QualityOption.fromJson)
        .toList();
    return (settings: settings, qualityOptions: quality);
  }

  Future<void> updateSettings(RemoteSettings settings) async {
    final result = await _post('/settings', settings.toJson());
    if (result['ok'] != true) {
      throw CastApiException(
          result['error'] as String? ?? 'Failed to save settings');
    }
  }
}
