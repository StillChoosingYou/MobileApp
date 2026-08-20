import 'package:flutter/foundation.dart';

/// Attendance status for a student in a session.
enum AttendanceStatus {
  present('Present', '✅'),
  absent('Absent', '❌'),
  late('Late', '⏰'),
  excused('Excused', '📋');

  const AttendanceStatus(this.label, this.icon);
  final String label;
  final String icon;
}

/// Summary of a student's attendance for a section.
@immutable
class AttendanceSummary {
  const AttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    required this.totalSessions,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
  });

  final String studentId;
  final String studentName;
  final String studentNumber;
  final int totalSessions;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;

  /// Attendance rate as a percentage (0-100).
  double get attendanceRate {
    if (totalSessions == 0) return 100.0;
    final attended = presentCount + lateCount + excusedCount;
    return (attended / totalSessions * 100).clamp(0.0, 100.0);
  }

  /// Whether the student is at risk (below 75% attendance).
  bool get isAtRisk => attendanceRate < 75.0;

  /// Color for the attendance rate display.
  String get statusLabel {
    if (attendanceRate >= 90) return 'Excellent';
    if (attendanceRate >= 75) return 'Good';
    if (attendanceRate >= 50) return 'At Risk';
    return 'Critical';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceSummary &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          studentName == other.studentName &&
          studentNumber == other.studentNumber &&
          totalSessions == other.totalSessions &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          lateCount == other.lateCount &&
          excusedCount == other.excusedCount;

  @override
  int get hashCode => Object.hash(
        studentId,
        studentName,
        studentNumber,
        totalSessions,
        presentCount,
        absentCount,
        lateCount,
        excusedCount,
      );

  @override
  String toString() => 'AttendanceSummary($studentName: ${attendanceRate.toStringAsFixed(1)}%)';
}

/// Individual attendance record for a student in a session.
@immutable
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.sectionId,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.recordedAt,
    this.method = AttendanceMethod.qrScan,
    this.latitude,
    this.longitude,
    this.notes,
  });

  final String id;
  final String sessionId;
  final String sectionId;
  final String studentId;
  final String studentName;
  final AttendanceStatus status;
  final DateTime recordedAt;
  final AttendanceMethod method;
  final double? latitude;
  final double? longitude;
  final String? notes;

  /// Create a copy with modified fields.
  AttendanceRecord copyWith({
    String? id,
    String? sessionId,
    String? sectionId,
    String? studentId,
    String? studentName,
    AttendanceStatus? status,
    DateTime? recordedAt,
    AttendanceMethod? method,
    double? latitude,
    double? longitude,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sectionId: sectionId ?? this.sectionId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      status: status ?? this.status,
      recordedAt: recordedAt ?? this.recordedAt,
      method: method ?? this.method,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          sectionId == other.sectionId &&
          studentId == other.studentId &&
          studentName == other.studentName &&
          status == other.status &&
          recordedAt == other.recordedAt &&
          method == other.method &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
        id,
        sessionId,
        sectionId,
        studentId,
        studentName,
        status,
        recordedAt,
        method,
        latitude,
        longitude,
        notes,
      );

  @override
  String toString() =>
      'AttendanceRecord($studentName: ${status.label} at ${recordedAt.toIso8601String()})';
}

/// Method used to record attendance.
enum AttendanceMethod {
  qrScan('QR Scan'),
  manual('Manual Entry'),
  gps('GPS Verification'),
  biometric('Biometric');

  const AttendanceMethod(this.label);
  final String label;
}

/// Attendance session with rotating QR code.
@immutable
class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.sectionId,
    required this.sectionName,
    required this.subjectCode,
    required this.startedAt,
    required this.expiresAt,
    required this.qrPayload,
    required this.rotationIntervalSeconds,
    this.facultyId,
    this.facultyName,
    this.isActive = true,
  });

  final String id;
  final String sectionId;
  final String sectionName;
  final String subjectCode;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String qrPayload; // Current QR payload (rotates)
  final int rotationIntervalSeconds;
  final String? facultyId;
  final String? facultyName;
  final bool isActive;

  /// Whether the session is still active (not expired).
  bool get isSessionActive => DateTime.now().isBefore(expiresAt) && isActive;

  /// Remaining time until session expires.
  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return Duration.zero;
    if (diff > const Duration(days: 1)) return const Duration(days: 1);
    return diff;
  }

  /// Progress of the session (0.0 to 1.0).
  double get progress {
    final total = expiresAt.difference(startedAt).inSeconds;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Get the next QR payload (for rotation simulation).
  String getNextQrPayload() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${qrPayload}_$timestamp';
  }

  AttendanceSession copyWith({
    String? id,
    String? sectionId,
    String? sectionName,
    String? subjectCode,
    DateTime? startedAt,
    DateTime? expiresAt,
    String? qrPayload,
    int? rotationIntervalSeconds,
    String? facultyId,
    String? facultyName,
    bool? isActive,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      subjectCode: subjectCode ?? this.subjectCode,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      qrPayload: qrPayload ?? this.qrPayload,
      rotationIntervalSeconds: rotationIntervalSeconds ?? this.rotationIntervalSeconds,
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sectionId == other.sectionId &&
          sectionName == other.sectionName &&
          subjectCode == other.subjectCode &&
          startedAt == other.startedAt &&
          expiresAt == other.expiresAt &&
          qrPayload == other.qrPayload &&
          rotationIntervalSeconds == other.rotationIntervalSeconds &&
          facultyId == other.facultyId &&
          facultyName == other.facultyName &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        id,
        sectionId,
        sectionName,
        subjectCode,
        startedAt,
        expiresAt,
        qrPayload,
        rotationIntervalSeconds,
        facultyId,
        facultyName,
        isActive,
      );

  @override
  String toString() =>
      'AttendanceSession($sectionName - $subjectCode, active: $isSessionActive, '
      'remaining: ${remainingTime.inMinutes}min)';
}

/// Result of QR code validation.
@immutable
class QrValidationResult {
  const QrValidationResult({
    required this.isValid,
    this.session,
    this.errorMessage,
    this.alreadyRecorded = false,
    this.wrongSection = false,
  });

  final bool isValid;
  final AttendanceSession? session;
  final String? errorMessage;
  final bool alreadyRecorded;
  final bool wrongSection;

  static QrValidationResult valid(AttendanceSession session) =>
      QrValidationResult(isValid: true, session: session);

  static QrValidationResult invalid(String error) =>
      QrValidationResult(isValid: false, errorMessage: error);

  static QrValidationResult alreadyRecordedResult(AttendanceSession session) =>
      QrValidationResult(isValid: false, session: session, alreadyRecorded: true);

  static QrValidationResult wrongSectionResult(AttendanceSession session) =>
      QrValidationResult(isValid: false, session: session, wrongSection: true);
}

/// QR payload data structure for encoding/decoding.
@immutable
class QrPayload {
  const QrPayload({
    required this.sessionId,
    required this.sectionId,
    required this.timestamp,
    required this.signature,
    this.facultyId,
  });

  final String sessionId;
  final String sectionId;
  final int timestamp; // milliseconds since epoch
  final String signature; // HMAC or simple hash for validation
  final String? facultyId;

  /// Encode to string for QR generation.
  String encode() {
    return 'PGPC_ATTENDANCE|$sessionId|$sectionId|$timestamp|$signature|${facultyId ?? ''}';
  }

  /// Decode from QR string.
  static QrPayload? decode(String qrString) {
    try {
      if (!qrString.startsWith('PGPC_ATTENDANCE|')) return null;
      final parts = qrString.split('|');
      if (parts.length < 5) return null;

      return QrPayload(
        sessionId: parts[1],
        sectionId: parts[2],
        timestamp: int.parse(parts[3]),
        signature: parts[4],
        facultyId: parts.length > 5 && parts[5].isNotEmpty ? parts[5] : null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if QR is expired (older than rotation interval).
  bool isExpired(int rotationIntervalSeconds) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = (now - timestamp) / 1000;
    return age > rotationIntervalSeconds;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrPayload &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          sectionId == other.sectionId &&
          timestamp == other.timestamp &&
          signature == other.signature &&
          facultyId == other.facultyId;

  @override
  int get hashCode =>
      Object.hash(sessionId, sectionId, timestamp, signature, facultyId);

  @override
  String toString() => 'QrPayload(session: $sessionId, section: $sectionId, '
      'time: ${DateTime.fromMillisecondsSinceEpoch(timestamp)})';
}