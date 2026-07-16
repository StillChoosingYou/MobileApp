class Announcement {
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

class NotificationItem {
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
