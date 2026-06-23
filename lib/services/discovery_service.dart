import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import '../models/cast_server.dart';

class DiscoveryService extends ChangeNotifier {
  static const String serviceType = '_wailscast._tcp';

  BonsoirDiscovery? _discovery;
  final List<CastServer> _servers = [];
  bool _isDiscovering = false;
  String? _error;

  List<CastServer> get servers => List.unmodifiable(_servers);
  bool get isDiscovering => _isDiscovering;
  String? get error => _error;

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    _error = null;
    try {
      _discovery = BonsoirDiscovery(type: serviceType);
      await _discovery!.ready;

      _discovery!.eventStream?.listen((event) {
        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          event.service?.resolve(_discovery!.serviceResolver);
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
          final service = event.service as ResolvedBonsoirService?;
          if (service != null) {
            final host = service.host;
            if (host != null) {
              final server = CastServer(
                name: service.name,
                host: host,
                port: service.port,
              );
              if (!_servers.any((s) => s.host == server.host && s.port == server.port)) {
                _servers.add(server);
                notifyListeners();
              }
            }
          }
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
          final service = event.service;
          if (service != null) {
            _servers.removeWhere((s) => s.name == service.name);
            notifyListeners();
          }
        }
      });

      await _discovery!.start();
      _isDiscovering = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isDiscovering = false;
      notifyListeners();
    }
  }

  Future<void> stopDiscovery() async {
    await _discovery?.stop();
    _isDiscovering = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _discovery?.stop();
    super.dispose();
  }
}
