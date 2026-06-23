import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/cast_client.dart';
import '../controllers/cast_controller.dart';
import '../models/cast_device.dart';
import '../models/cast_server.dart';
import '../models/library_item.dart';
import '../models/playback_state.dart';
import '../widgets/play_options_sheet.dart';
import 'now_playing_screen.dart';
import 'settings_screen.dart';

class LibraryScreen extends StatefulWidget {
  final CastServer server;
  final CastClient client;

  const LibraryScreen({super.key, required this.server, required this.client});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final CastController _controller;

  List<LibraryItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller =
        CastController(client: widget.client, serverName: widget.server.name);
    _controller.startPolling();
    _controller.loadDevices();
    _loadLibrary();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.client.getLibrary();
      setState(() {
        _items = items;
        _loading = false;
      });
    } on CastApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load library: $e';
        _loading = false;
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }

  Future<void> _openPlayOptions(LibraryItem item) async {
    final started = await showPlayOptions(context, _controller, item);
    if (started == true) _openNowPlaying();
  }

  void _openNowPlaying() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: _controller,
        child: const NowPlayingScreen(),
      ),
    ));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(client: widget.client),
    ));
  }

  // ─── Output device picker ──────────────────────────────────────────────────
  void _pickDevice() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: _controller,
        child: Consumer<CastController>(
          builder: (ctx, c, _) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                  child: Row(
                    children: [
                      Text('Output device',
                          style: Theme.of(ctx).textTheme.titleMedium),
                      const Spacer(),
                      if (c.loadingDevices)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Rescan devices',
                          onPressed: c.loadDevices,
                        ),
                    ],
                  ),
                ),
                RadioGroup<CastDevice>(
                  groupValue: c.selectedDevice,
                  onChanged: (v) {
                    if (v != null) c.selectDevice(v);
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: c.devices
                        .map((d) => RadioListTile<CastDevice>(
                              value: d,
                              title: Text(d.name),
                              subtitle: d.isLocal
                                  ? const Text('Play on the desktop')
                                  : Text('${d.host}:${d.port}'),
                              secondary: Icon(
                                  d.isLocal ? Icons.computer : Icons.cast),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Play URL ───────────────────────────────────────────────────────────────
  void _showPlayUrlDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Play URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://example.com/video.mp4',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final url = controller.text.trim();
              Navigator.pop(ctx);
              if (url.isEmpty) return;
              try {
                await _controller.playUrl(url);
                _openNowPlaying();
              } on CastApiException catch (e) {
                _snack(e.message, error: true);
              } catch (e) {
                _snack('$e', error: true);
              }
            },
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadLibrary,
            ),
          ],
        ),
      );
    } else if (_items.isEmpty) {
      body = const Center(child: Text('Library is empty'));
    } else {
      body = RefreshIndicator(
        onRefresh: _loadLibrary,
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final item = _items[i];
            return ListTile(
              leading: const Icon(Icons.movie_outlined),
              title: Text(item.name),
              subtitle: Text(
                [
                  if (item.path.isNotEmpty) item.path,
                  if (item.durationFormatted.isNotEmpty) item.durationFormatted,
                ].join('  ·  '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.play_circle_outline),
              onTap: () => _openPlayOptions(item),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Play URL',
            onPressed: _showPlayUrlDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh library',
            onPressed: _loading ? null : _loadLibrary,
          ),
        ],
      ),
      body: Column(
        children: [
          _DeviceBar(controller: _controller, onTap: _pickDevice),
          Expanded(child: body),
          _NowPlayingBar(controller: _controller, onTap: _openNowPlaying),
        ],
      ),
    );
  }
}

/// The output-device selector shown under the app bar.
class _DeviceBar extends StatelessWidget {
  final CastController controller;
  final VoidCallback onTap;
  const _DeviceBar({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final device = controller.selectedDevice;
        return Material(
          color: theme.colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(device.isLocal ? Icons.computer : Icons.cast,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Output device',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            )),
                        Text(device.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (controller.loadingDevices)
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    const Icon(Icons.expand_more),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Compact now-playing bar at the bottom; tap to open full controls.
class _NowPlayingBar extends StatelessWidget {
  final CastController controller;
  final VoidCallback onTap;
  const _NowPlayingBar({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        if (!state.isActive) return const SizedBox.shrink();
        return Material(
          color: theme.colorScheme.primaryContainer,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.movie_creation_outlined,
                      color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.mediaName,
                            style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          state.duration > 0
                              ? '${PlaybackState.formatTime(state.currentTime)} / ${PlaybackState.formatTime(state.duration)}'
                              : (state.isPaused ? 'Paused' : 'Playing'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      state.isPaused ? Icons.play_arrow : Icons.pause,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () async {
                      try {
                        final s = state.isPaused
                            ? await controller.client.control('resume')
                            : await controller.client.control('pause');
                        controller.applyState(s);
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
