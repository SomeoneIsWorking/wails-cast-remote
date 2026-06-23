import 'package:flutter/material.dart';
import '../api/cast_client.dart';
import '../models/track_info.dart';

class SettingsScreen extends StatefulWidget {
  final CastClient client;
  const SettingsScreen({super.key, required this.client});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  RemoteSettings _settings = const RemoteSettings();
  List<QualityOption> _qualityOptions = const [];
  final _languageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.client.getSettings();
      setState(() {
        _settings = res.settings;
        _qualityOptions = res.qualityOptions;
        _languageController.text = res.settings.defaultTranslationLanguage;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final toSave = _settings.copyWith(
        defaultTranslationLanguage: _languageController.text.trim(),
      );
      await widget.client.updateSettings(toSave);
      setState(() => _settings = toSave);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
    } on CastApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
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
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _load,
            ),
          ],
        ),
      );
    } else {
      final qualityValid =
          _qualityOptions.any((q) => q.value == _settings.defaultQuality);
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Subtitles', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Subtitle font size'),
            subtitle: Slider(
              value: _settings.subtitleFontSize.toDouble().clamp(10, 60),
              min: 10,
              max: 60,
              divisions: 50,
              label: '${_settings.subtitleFontSize}',
              onChanged: (v) => setState(() => _settings =
                  _settings.copyWith(subtitleFontSize: v.round())),
            ),
            trailing: Text('${_settings.subtitleFontSize}',
                style: theme.textTheme.titleMedium),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Burn subtitles into video'),
            subtitle: const Text('Render subtitles server-side'),
            value: _settings.subtitleBurnIn,
            onChanged: (v) => setState(
                () => _settings = _settings.copyWith(subtitleBurnIn: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ignore closed captions'),
            value: _settings.ignoreClosedCaptions,
            onChanged: (v) => setState(() =>
                _settings = _settings.copyWith(ignoreClosedCaptions: v)),
          ),
          const Divider(height: 32),
          Text('Playback', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue:
                qualityValid ? _settings.defaultQuality : _qualityOptions.first.value,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Default quality',
              border: OutlineInputBorder(),
            ),
            items: _qualityOptions
                .map((q) =>
                    DropdownMenuItem(value: q.value, child: Text(q.label)))
                .toList(),
            onChanged: (v) => setState(() =>
                _settings = _settings.copyWith(defaultQuality: v)),
          ),
          const Divider(height: 32),
          Text('Translation', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _languageController,
            decoration: const InputDecoration(
              labelText: 'Default translation language',
              hintText: 'e.g. English, Turkish',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.translate),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving…' : 'Save'),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: body,
    );
  }
}
