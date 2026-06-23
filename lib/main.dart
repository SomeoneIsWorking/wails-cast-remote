import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/discovery_service.dart';
import 'screens/discovery_screen.dart';

void main() {
  runApp(const WailsCastRemoteApp());
}

class WailsCastRemoteApp extends StatelessWidget {
  const WailsCastRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiscoveryService()..startDiscovery(),
      child: MaterialApp(
        title: 'WailsCast Remote',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const DiscoveryScreen(),
      ),
    );
  }
}
