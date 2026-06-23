import 'package:flutter/material.dart';
import '../api/cast_client.dart';

/// Prompts for a target language, starts a subtitle translation for [id], and
/// shows a progress dialog until it finishes. Returns the language that was
/// translated on success, or null if cancelled / failed.
Future<String?> runTranslateFlow(
  BuildContext context,
  CastClient client, {
  required String id,
  required String name,
  String defaultLanguage = '',
}) async {
  final langController = TextEditingController(text: defaultLanguage);
  final lang = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Translate subtitles'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: Theme.of(ctx).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          TextField(
            controller: langController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Target language',
              hintText: 'e.g. English',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, langController.text.trim()),
          child: const Text('Translate'),
        ),
      ],
    ),
  );
  if (lang == null || lang.isEmpty) return null;
  if (!context.mounted) return null;

  String language;
  try {
    language = await client.translate(id, language: lang);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is CastApiException ? e.message : '$e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
    return null;
  }

  if (!context.mounted) return null;
  final ok = await _showProgress(context, client, language);
  return ok ? language : null;
}

Future<bool> _showProgress(
    BuildContext context, CastClient client, String language) async {
  bool done = false;
  bool success = false;
  String? error;
  int fileCount = 0;
  bool polling = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        Future<void> poll() async {
          polling = true;
          while (!done && ctx.mounted) {
            await Future.delayed(const Duration(seconds: 2));
            try {
              final status = await client.getTranslateStatus();
              if (!status.inProgress) {
                done = true;
                error = status.error.isEmpty ? null : status.error;
                success = status.error.isEmpty;
                fileCount = status.files.length;
                if (ctx.mounted) setDialogState(() {});
                break;
              }
            } catch (_) {}
          }
        }

        if (!polling) poll();

        return AlertDialog(
          title: Text(done ? 'Translation finished' : 'Translating…'),
          content: Row(
            children: [
              if (!done)
                const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(error == null ? Icons.check_circle : Icons.error,
                    color: error == null
                        ? Colors.green
                        : Theme.of(ctx).colorScheme.error),
              const SizedBox(width: 16),
              Expanded(
                child: Text(done
                    ? (error == null
                        ? 'Done — $fileCount file(s) written ($language).'
                        : 'Error: $error')
                    : 'Translating subtitles to $language.\nThis can take a while.'),
              ),
            ],
          ),
          actions: [
            if (done)
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
          ],
        );
      },
    ),
  );
  return success;
}
