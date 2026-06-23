import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/cast_client.dart';
import '../models/cast_server.dart';
import '../services/discovery_service.dart';
import 'library_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '9999');
  final _tokenController = TextEditingController();
  bool _connecting = false;
  String? _connectError;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hostController.text = prefs.getString('last_host') ?? '';
      _portController.text = prefs.getString('last_port') ?? '9999';
      _tokenController.text = prefs.getString('last_token') ?? '';
    });
  }

  Future<void> _savePrefs(String host, String port, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_host', host);
    await prefs.setString('last_port', port);
    await prefs.setString('last_token', token);
  }

  Future<void> _connectTo(CastServer server) async {
    setState(() {
      _connecting = true;
      _connectError = null;
    });
    try {
      final client = CastClient(
        host: server.host,
        port: server.port,
        token: server.token,
      );
      await client.ping();
      await _savePrefs(server.host, server.port.toString(), server.token ?? '');
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LibraryScreen(server: server, client: client),
        ),
      );
    } on CastApiException catch (e) {
      setState(() => _connectError = e.message);
    } catch (e) {
      setState(() => _connectError = 'Connection failed: $e');
    } finally {
      setState(() => _connecting = false);
    }
  }

  Future<void> _connectManual() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9999;
    final token = _tokenController.text.trim();
    if (host.isEmpty) {
      setState(() => _connectError = 'Please enter a host');
      return;
    }
    final server = CastServer(
      name: host,
      host: host,
      port: port,
      token: token.isEmpty ? null : token,
    );
    await _connectTo(server);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WailsCast Remote'),
        actions: [
          if (discovery.isDiscovering)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart discovery',
            onPressed: () {
              context.read<DiscoveryService>()
                ..stopDiscovery()
                ..startDiscovery();
            },
          ),
        ],
      ),
      body: _connecting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (discovery.servers.isNotEmpty) ...[
                    Text('Discovered', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...discovery.servers.map((s) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.cast),
                            title: Text(s.name),
                            subtitle: Text('${s.host}:${s.port}'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => _connectTo(s),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],
                  Text('Manual Connection', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host / IP',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.computer),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Auth Token (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (_connectError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _connectError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text('Connect'),
                      onPressed: _connectManual,
                    ),
                  ),
                  if (discovery.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Discovery error: ${discovery.error}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
