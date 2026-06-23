import 'package:flutter/material.dart';
import '../api/cast_client.dart';
import '../controllers/cast_controller.dart';
import '../models/library_item.dart';
import '../models/track_info.dart';
import 'translate_flow.dart';

/// Shows a bottom sheet that loads the media's tracks and lets the user pick
/// video/audio/subtitle/quality before playing on the controller's selected
/// device. Returns true if playback was started.
Future<bool?> showPlayOptions(
  BuildContext context,
  CastController controller,
  LibraryItem item,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PlayOptionsSheet(controller: controller, item: item),
  );
}

class _PlayOptionsSheet extends StatefulWidget {
  final CastController controller;
  final LibraryItem item;
  const _PlayOptionsSheet({required this.controller, required this.item});

  @override
  State<_PlayOptionsSheet> createState() => _PlayOptionsSheetState();
}

class _PlayOptionsSheetState extends State<_PlayOptionsSheet> {
  bool _loading = true;
  String? _error;
  bool _playing = false;

  TrackInfo _tracks = const TrackInfo();
  List<QualityOption> _qualityOptions = const [];

  int _videoTrack = 0;
  int _audioTrack = 0;
  String _subtitlePath = 'none';
  String? _quality; // null = default

  // Translation status (for the default language).
  bool _translated = false;
  String _defaultLanguage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = widget.controller.client;
      final results = await Future.wait([
        client.getTrackInfo(widget.item.id),
        client.getSettings(),
        client.getTranslationInfo(widget.item.id),
      ]);
      final tracks = results[0] as TrackInfo;
      final settings = results[1]
          as ({RemoteSettings settings, List<QualityOption> qualityOptions});
      final translation = results[2]
          as ({bool translated, String language, String subtitlePath});

      setState(() {
        _tracks = tracks;
        _qualityOptions = settings.qualityOptions;
        _translated = translation.translated;
        _defaultLanguage = translation.language.isNotEmpty
            ? translation.language
            : settings.settings.defaultTranslationLanguage;
        _videoTrack = tracks.videoTracks.isNotEmpty
            ? tracks.videoTracks.first.index
            : 0;
        _audioTrack = tracks.audioTracks.isNotEmpty
            ? tracks.audioTracks.first.index
            : 0;
        // Default subtitle: prefer a detected nearby/translated subtitle.
        _subtitlePath =
            tracks.nearSubtitle.isNotEmpty ? tracks.nearSubtitle : 'none';
        _quality = settings.settings.defaultQuality;
        _loading = false;
      });
    } on CastApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _play() async {
    setState(() => _playing = true);
    try {
      await widget.controller.play(
        widget.item,
        options: PlayOptions(
          videoTrack: _videoTrack,
          audioTrack: _audioTrack,
          subtitlePath: _subtitlePath,
          quality: _quality,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on CastApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _translate() async {
    final language = await runTranslateFlow(
      context,
      widget.controller.client,
      id: widget.item.id,
      name: widget.item.name,
      defaultLanguage: _defaultLanguage,
    );
    if (language != null && mounted) {
      // Refresh so the new translation status and subtitle option appear.
      await _load();
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = widget.controller.selectedDevice;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item.name,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(device.isLocal ? Icons.computer : Icons.cast,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text('Play on ${device.name}',
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ErrorBlock(message: _error!, onRetry: _load)
          else
            _buildPickers(theme),
          if (!_loading && _error == null) ...[
            const SizedBox(height: 4),
            _translationRow(theme),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _playing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: Text(_playing ? 'Starting…' : 'Play'),
              onPressed: (_loading || _error != null || _playing) ? null : _play,
            ),
          ),
        ],
      ),
    );
  }

  Widget _translationRow(ThemeData theme) {
    final lang = _defaultLanguage.isEmpty ? '' : ' ($_defaultLanguage)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _translated ? Icons.check_circle : Icons.translate,
            size: 20,
            color: _translated ? Colors.green : theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _translated
                  ? 'Subtitles translated$lang'
                  : 'Not translated$lang',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.translate, size: 18),
            label: Text(_translated ? 'Re-translate' : 'Translate'),
            onPressed: _playing ? null : _translate,
          ),
        ],
      ),
    );
  }

  Widget _buildPickers(ThemeData theme) {
    final subtitleItems = [
      ..._tracks.subtitleTracks,
      // Ensure a detected nearby subtitle is selectable even if not listed.
      if (_tracks.nearSubtitle.isNotEmpty &&
          !_tracks.subtitleTracks.any((s) => s.path == _tracks.nearSubtitle))
        SubtitleTrack(path: _tracks.nearSubtitle, label: 'Detected subtitle'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_tracks.videoTracks.length > 1)
          _Dropdown<int>(
            label: 'Video',
            value: _videoTrack,
            items: _tracks.videoTracks
                .map((v) => DropdownMenuItem(value: v.index, child: Text(v.label)))
                .toList(),
            onChanged: (v) => setState(() => _videoTrack = v!),
          ),
        if (_tracks.audioTracks.length > 1)
          _Dropdown<int>(
            label: 'Audio',
            value: _audioTrack,
            items: _tracks.audioTracks
                .map((a) => DropdownMenuItem(value: a.index, child: Text(a.label)))
                .toList(),
            onChanged: (v) => setState(() => _audioTrack = v!),
          ),
        if (subtitleItems.isNotEmpty)
          _Dropdown<String>(
            label: 'Subtitle',
            value: subtitleItems.any((s) => s.path == _subtitlePath)
                ? _subtitlePath
                : subtitleItems.first.path,
            items: subtitleItems
                .map((s) =>
                    DropdownMenuItem(value: s.path, child: Text(s.label)))
                .toList(),
            onChanged: (v) => setState(() => _subtitlePath = v!),
          ),
        if (_qualityOptions.isNotEmpty)
          _Dropdown<String>(
            label: 'Quality',
            value: _qualityOptions.any((q) => q.value == _quality)
                ? _quality!
                : _qualityOptions.first.value,
            items: _qualityOptions
                .map((q) =>
                    DropdownMenuItem(value: q.value, child: Text(q.label)))
                .toList(),
            onChanged: (v) => setState(() => _quality = v),
          ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 36),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          onPressed: onRetry,
        ),
      ],
    );
  }
}
