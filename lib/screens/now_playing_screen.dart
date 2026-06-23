import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/cast_client.dart';
import '../controllers/cast_controller.dart';
import '../models/playback_state.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  double? _seekPreview; // non-null while the user is dragging the seek slider
  double? _volumePreview;

  CastController get _c => context.read<CastController>();

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on CastApiException catch (e) {
      _snack(e.message, error: true);
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CastController>();
    final state = controller.state;
    final theme = Theme.of(context);

    final duration = state.duration;
    final position = _seekPreview ?? state.currentTime;
    final volume = _volumePreview ?? state.volume;

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Icon(Icons.movie_creation_outlined,
                size: 96, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              state.mediaName.isEmpty ? 'Nothing playing' : state.mediaName,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              state.deviceName.isEmpty
                  ? controller.selectedDevice.name
                  : state.deviceName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              _statusLabel(state),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),

            // Seek bar
            if (duration > 0) ...[
              Slider(
                value: position.clamp(0, duration),
                max: duration,
                onChanged: (v) => setState(() => _seekPreview = v),
                onChangeEnd: (v) async {
                  setState(() => _seekPreview = null);
                  await _guard(() => _c.client.seek(v));
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(PlaybackState.formatTime(position)),
                    Text(PlaybackState.formatTime(duration)),
                  ],
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Live / position unavailable'),
              ),

            const SizedBox(height: 8),

            // Transport controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.replay_10),
                  tooltip: 'Back 10s',
                  onPressed: duration <= 0
                      ? null
                      : () => _guard(() => _c.client
                          .seek((position - 10).clamp(0, duration))),
                ),
                IconButton.filled(
                  iconSize: 56,
                  icon: Icon(state.isPaused
                      ? Icons.play_arrow
                      : Icons.pause),
                  tooltip: state.isPaused ? 'Resume' : 'Pause',
                  onPressed: () => _guard(() async {
                    final s = state.isPaused
                        ? await _c.client.control('resume')
                        : await _c.client.control('pause');
                    _c.applyState(s);
                  }),
                ),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.forward_30),
                  tooltip: 'Forward 30s',
                  onPressed: duration <= 0
                      ? null
                      : () => _guard(() => _c.client
                          .seek((position + 30).clamp(0, duration))),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Volume
            Row(
              children: [
                IconButton(
                  icon: Icon(state.muted ? Icons.volume_off : Icons.volume_up),
                  tooltip: state.muted ? 'Unmute' : 'Mute',
                  onPressed: () => _guard(() async {
                    final s = await _c.client.control(
                        state.muted ? 'unmute' : 'mute');
                    _c.applyState(s);
                  }),
                ),
                Expanded(
                  child: Slider(
                    value: volume.clamp(0, 1),
                    onChanged: (v) => setState(() => _volumePreview = v),
                    onChangeEnd: (v) async {
                      setState(() => _volumePreview = null);
                      await _guard(() => _c.client.setVolume(v));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                onPressed: () => _guard(() async {
                  final navigator = Navigator.of(context);
                  await _c.client.stop();
                  await _c.refreshState();
                  if (mounted) navigator.pop();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(PlaybackState s) {
    switch (s.status) {
      case 'PLAYING':
        return 'Playing';
      case 'PAUSED':
        return 'Paused';
      case 'STOPPED':
        return 'Stopped';
      default:
        return s.mediaName.isEmpty ? '' : 'Ready';
    }
  }
}
