class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actor,
    required this.action,
    required this.target,
    required this.timestamp,
  });

  final String id;
  final String actor;
  final String action;
  final String target;
  final DateTime timestamp;
}
