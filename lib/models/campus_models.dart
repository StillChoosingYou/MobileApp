import 'package:flutter/material.dart';

class Announcement {

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        category: json['category'] as String,
        postedAt: DateTime.parse(json['postedAt'] as String),
      );
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.postedAt,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime postedAt;
}

/// A promotional announcement specifically for the top ticker banner.
/// Includes promotional-specific fields like background color, action button,
/// and display priority.
class PromotionalAnnouncement {

  factory PromotionalAnnouncement.fromJson(Map<String, dynamic> json) => PromotionalAnnouncement(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        category: json['category'] as String,
        postedAt: DateTime.parse(json['postedAt'] as String),
        backgroundColor: json['backgroundColor'] != null
            ? Color(json['backgroundColor'] as int)
            : null,
        textColor: json['textColor'] != null
            ? Color(json['textColor'] as int)
            : null,
        actionLabel: json['actionLabel'] as String?,
        actionUrl: json['actionUrl'] as String?,
        iconCodePoint: json['iconCodePoint'] as int?,
        iconFontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
        priority: json['priority'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String)
            : null,
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
      );

  const PromotionalAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.postedAt,
    this.backgroundColor,
    this.textColor,
    this.actionLabel,
    this.actionUrl,
    this.iconCodePoint,
    this.iconFontFamily,
    this.priority = 0,
    this.isActive = true,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime postedAt;

  // Promotional-specific fields
  final Color? backgroundColor;
  final Color? textColor;
  final String? actionLabel;
  final String? actionUrl;
  final int? iconCodePoint;
  final String? iconFontFamily;
  final int priority;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Whether this announcement should be displayed right now
  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Get the icon widget if available
  Icon? get icon {
    if (iconCodePoint == null || iconFontFamily == null) return null;
    return Icon(
      IconData(iconCodePoint!, fontFamily: iconFontFamily),
      size: 16,
    );
  }

  /// Convert to a regular Announcement for compatibility
  Announcement toAnnouncement() => Announcement(
        id: id,
        title: title,
        body: body,
        category: category,
        postedAt: postedAt,
      );
}

class NotificationItem {

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        read: json['read'] as bool? ?? false,
      );
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;

  NotificationItem markRead() => NotificationItem(
        id: id,
        title: title,
        body: body,
        timestamp: timestamp,
        read: true,
      );
}

enum DocumentType { transcriptOfRecords, certificateOfEnrollment, goodMoral, diplomaCopy }

extension DocumentTypeLabel on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.transcriptOfRecords:
        return 'Transcript of Records';
      case DocumentType.certificateOfEnrollment:
        return 'Certificate of Enrollment';
      case DocumentType.goodMoral:
        return 'Good Moral Certificate';
      case DocumentType.diplomaCopy:
        return 'Diploma Copy';
    }
  }
}

enum RequestStatus { submitted, processing, ready, released }

extension RequestStatusLabel on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.submitted:
        return 'Submitted';
      case RequestStatus.processing:
        return 'Processing';
      case RequestStatus.ready:
        return 'Ready for pickup';
      case RequestStatus.released:
        return 'Released';
    }
  }
}

class DocumentRequest {
  const DocumentRequest({
    required this.id,
    required this.studentId,
    required this.type,
    required this.purpose,
    required this.requestedAt,
    required this.status,
  });

  final String id;
  final String studentId;
  final DocumentType type;
  final String purpose;
  final DateTime requestedAt;
  final RequestStatus status;

  DocumentRequest copyWith({RequestStatus? status}) => DocumentRequest(
        id: id,
        studentId: studentId,
        type: type,
        purpose: purpose,
        requestedAt: requestedAt,
        status: status ?? this.status,
      );
}

class ClearanceStep {
  const ClearanceStep({
    required this.office,
    required this.cleared,
    this.clearedBy,
  });

  final String office;
  final bool cleared;
  final String? clearedBy;

  ClearanceStep copyWith({bool? cleared, String? clearedBy}) => ClearanceStep(
        office: office,
        cleared: cleared ?? this.cleared,
        clearedBy: clearedBy ?? this.clearedBy,
      );
}

class Clearance {
  const Clearance({
    required this.studentId,
    required this.term,
    required this.steps,
  });

  final String studentId;
  final String term;
  final List<ClearanceStep> steps;

  bool get isComplete => steps.every((s) => s.cleared);
  int get clearedCount => steps.where((s) => s.cleared).length;
}

enum QueueOffice { registrar, accounting, cashier, guidance }

extension QueueOfficeLabel on QueueOffice {
  String get label {
    switch (this) {
      case QueueOffice.registrar:
        return 'Registrar';
      case QueueOffice.accounting:
        return 'Accounting';
      case QueueOffice.cashier:
        return 'Cashier';
      case QueueOffice.guidance:
        return 'Guidance';
    }
  }

  String get prefix {
    switch (this) {
      case QueueOffice.registrar:
        return 'R';
      case QueueOffice.accounting:
        return 'A';
      case QueueOffice.cashier:
        return 'C';
      case QueueOffice.guidance:
        return 'G';
    }
  }
}

enum QueueStatus { waiting, called, served, cancelled }

class QueueTicket {
  const QueueTicket({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.office,
    required this.number,
    required this.issuedAt,
    required this.status,
  });

  final String id;
  final String studentId;
  final String studentName;
  final QueueOffice office;
  final int number;
  final DateTime issuedAt;
  final QueueStatus status;

  String get displayNumber => '${office.prefix}-${number.toString().padLeft(3, '0')}';

  QueueTicket copyWith({QueueStatus? status}) => QueueTicket(
        id: id,
        studentId: studentId,
        studentName: studentName,
        office: office,
        number: number,
        issuedAt: issuedAt,
        status: status ?? this.status,
      );
}

enum AppointmentOffice { registrar, accounting, guidance, dean }

extension AppointmentOfficeLabel on AppointmentOffice {
  String get label {
    switch (this) {
      case AppointmentOffice.registrar:
        return 'Registrar';
      case AppointmentOffice.accounting:
        return 'Accounting';
      case AppointmentOffice.guidance:
        return 'Guidance';
      case AppointmentOffice.dean:
        return "Dean's Office";
    }
  }
}

enum AppointmentStatus { pending, confirmed, completed, cancelled }

class Appointment {
  const Appointment({
    required this.id,
    required this.studentId,
    required this.office,
    required this.purpose,
    required this.requestedFor,
    required this.status,
  });

  final String id;
  final String studentId;
  final AppointmentOffice office;
  final String purpose;
  final DateTime requestedFor;
  final AppointmentStatus status;
}

class VisitorLog {
  const VisitorLog({
    required this.id,
    required this.visitorName,
    required this.purpose,
    required this.hostName,
    required this.checkIn,
    this.checkOut,
  });

  final String id;
  final String visitorName;
  final String purpose;
  final String hostName;
  final DateTime checkIn;
  final DateTime? checkOut;

  bool get isOnCampus => checkOut == null;
}

class LostFoundItem {
  const LostFoundItem({
    required this.id,
    required this.isFound,
    required this.itemName,
    required this.description,
    required this.location,
    required this.reportedBy,
    required this.reportedAt,
    this.claimed = false,
  });

  final String id;

  /// true = reported as "found" by someone; false = reported "lost" by owner
  final bool isFound;
  final String itemName;
  final String description;
  final String location;
  final String reportedBy;
  final DateTime reportedAt;
  final bool claimed;

  LostFoundItem copyWith({bool? claimed}) => LostFoundItem(
        id: id,
        isFound: isFound,
        itemName: itemName,
        description: description,
        location: location,
        reportedBy: reportedBy,
        reportedAt: reportedAt,
        claimed: claimed ?? this.claimed,
      );
}
