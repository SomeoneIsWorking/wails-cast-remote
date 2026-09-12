import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wailscast_remote/api/cast_client.dart';
import 'package:wailscast_remote/models/cast_server.dart';

void main() {
  test('discovered IPv6 hosts remain valid HTTP authorities', () {
    final client = CastClient(host: '::1', port: 9999);
    const server = CastServer(name: 'Local', host: '::1', port: 9999);

    expect(client.baseUrl, 'http://[::1]:9999');
    expect(server.baseUrl, client.baseUrl);
  });

  test('translation query parameters survive endpoint construction', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((request) async {
      expect(request.uri.path, '/translation-info');
      expect(request.uri.queryParameters, {
        'id': 'show & episode',
        'language': 'fr Français',
      });
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        '{"translated":true,"language":"fr Français","subtitlePath":"caption.srt"}',
      );
      await request.response.close();
    });

    try {
      final client = CastClient(host: '127.0.0.1', port: server.port);
      final result = await client.getTranslationInfo(
        'show & episode',
        language: 'fr Français',
      );

      expect(result.translated, isTrue);
      expect(result.language, 'fr Français');
      expect(result.subtitlePath, 'caption.srt');
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  });
}
