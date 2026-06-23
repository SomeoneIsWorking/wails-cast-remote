import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/cast_client.dart';
import '../models/cast_device.dart';
import '../models/library_item.dart';
import '../models/playback_state.dart';

/// Holds the connection-scoped state shared across screens: the API client, the
/// list of cast targets, the currently selected output device, and a polled
/// snapshot of the desktop's playback state.
class CastController extends ChangeNotifier {
  final CastClient client;
  final String serverName;

  CastController({required this.client, required this.serverName});

  // ─── Devices ──────────────────────────────────────────────────────────────
  List<CastDevice> _devices = const [
    CastDevice(name: 'This Computer', host: 'local', port: 0, uuid: 'local'),
  ];
  CastDevice _selected =
      const CastDevice(name: 'This Computer', host: 'local', port: 0, uuid: 'local');
  bool _loadingDevices = false;

  List<CastDevice> get devices => _devices;
  CastDevice get selectedDevice => _selected;
  bool get loadingDevices => _loadingDevices;

  void selectDevice(CastDevice d) {
    _selected = d;
    notifyListeners();
  }

  Future<void> loadDevices() async {
    _loadingDevices = true;
    notifyListeners();
    try {
      final found = await client.getDevices();
      if (found.isNotEmpty) {
        _devices = found;
        // Keep the current selection if it is still present, else default to
        // the first entry (local).
        if (!_devices.any((d) => d == _selected)) {
          _selected = _devices.first;
        }
      }
    } catch (_) {
      // Leave the existing (local-only) list in place on failure.
    } finally {
      _loadingDevices = false;
      notifyListeners();
    }
  }

  // ─── Playback ────────────────────────────────────────────────────────────
  PlaybackState _state = const PlaybackState();
  Timer? _poll;

  PlaybackState get state => _state;

  void startPolling() {
    _poll ??= Timer.periodic(const Duration(seconds: 1), (_) => refreshState());
    refreshState();
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> refreshState() async {
    try {
      final s = await client.getState();
      if (s.status != _state.status ||
          s.currentTime != _state.currentTime ||
          s.mediaName != _state.mediaName ||
          s.volume != _state.volume ||
          s.muted != _state.muted) {
        _state = s;
        notifyListeners();
      }
    } catch (_) {
      // Ignore transient polling errors.
    }
  }

  /// Apply a state returned synchronously by a control/play call so the UI
  /// updates immediately without waiting for the next poll tick.
  void applyState(PlaybackState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> play(LibraryItem item, {PlayOptions? options}) async {
    await client.playItem(item.id,
        deviceIp: _selected.host, options: options);
    await refreshState();
  }

  Future<void> playUrl(String url, {PlayOptions? options}) async {
    await client.playUrl(url, deviceIp: _selected.host, options: options);
    await refreshState();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
