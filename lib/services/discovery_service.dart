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
    if (_isDiscovering) {
      return;
    }
    _error = null;
    try {
      final discovery = BonsoirDiscovery(type: serviceType);
      _discovery = discovery;
      await discovery.initialize();

      discovery.eventStream!.listen((event) {
        _handleEvent(event, discovery);
      });

      await discovery.start();
      _isDiscovering = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isDiscovering = false;
      notifyListeners();
    }
  }

  void _handleEvent(BonsoirDiscoveryEvent event, BonsoirDiscovery discovery) {
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      event.service.resolve(discovery.serviceResolver);
      return;
    }
    if (event is BonsoirDiscoveryServiceResolvedEvent ||
        event is BonsoirDiscoveryServiceUpdatedEvent) {
      final service = event.service;
      if (service == null) {
        return;
      }
      final host = service.hostAddress ?? service.hostname;
      if (host == null) {
        return;
      }
      final server =
          CastServer(name: service.name, host: host, port: service.port);
      final existing = _servers.indexWhere((s) => s.name == server.name);
      if (existing >= 0) {
        if (_servers[existing].host != server.host ||
            _servers[existing].port != server.port) {
          _servers[existing] = server;
          notifyListeners();
        }
      } else if (!_servers
          .any((s) => s.host == server.host && s.port == server.port)) {
        _servers.add(server);
        notifyListeners();
      }
      return;
    }
    if (event is BonsoirDiscoveryServiceLostEvent) {
      final removed = _servers.length;
      _servers.removeWhere((s) => s.name == event.service.name);
      if (_servers.length != removed) {
        notifyListeners();
      }
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
