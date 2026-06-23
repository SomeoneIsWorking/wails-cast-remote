/// A cast target returned by GET /devices. [host] is the value passed back to
/// the server as `deviceIp` when playing ("local" = the desktop itself).
class CastDevice {
  final String name;
  final String host;
  final int port;
  final String uuid;

  const CastDevice({
    required this.name,
    required this.host,
    required this.port,
    required this.uuid,
  });

  bool get isLocal => host == 'local';

  factory CastDevice.fromJson(Map<String, dynamic> json) {
    return CastDevice(
      name: json['name'] as String? ?? 'Unknown',
      host: json['host'] as String? ?? 'local',
      port: json['port'] as int? ?? 0,
      uuid: json['uuid'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CastDevice && other.host == host && other.uuid == uuid;

  @override
  int get hashCode => Object.hash(host, uuid);
}
