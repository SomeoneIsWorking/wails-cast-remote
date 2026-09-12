class CastServer {
  final String name;
  final String host;
  final int port;
  final String? token;

  const CastServer({
    required this.name,
    required this.host,
    required this.port,
    this.token,
  });

  String get baseUrl => Uri(scheme: 'http', host: host, port: port).toString();

  @override
  String toString() => '$name ($host:$port)';
}
