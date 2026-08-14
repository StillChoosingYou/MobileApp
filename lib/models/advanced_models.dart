/// Advanced models supporting the expanded feature set — evaluations,
/// scholarships, installment plans, counseling, curriculum tracking,
/// department performance, graduation evaluations, calendar events, and
/// user settings.
library;

// ---------------------------------------------------------------------------
// Faculty Evaluation (Student → Faculty)
// ---------------------------------------------------------------------------

class FacultyEvaluation {
  const FacultyEvaluation({
    required this.id,
    required this.studentId,
    required this.facultyName,
    required this.sectionId,
    required this.term,
    required this.rating,
    this.comment,
    required this.submittedAt,
  });

  final String id;
  final String studentId;
  final String facultyName;
  final String sectionId;
  final String term;

  /// 1–5 star rating.
  final int rating;
  final String? comment;
  final DateTime submittedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'facultyName': facultyName,
        'sectionId': sectionId,
        'term': term,
        'rating': rating,
        'comment': comment,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory FacultyEvaluation.fromJson(Map<String, dynamic> json) =>
      FacultyEvaluation(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        facultyName: json['facultyName'] as String,
        sectionId: json['sectionId'] as String,
        term: json['term'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// Scholarship
// ---------------------------------------------------------------------------

enum ScholarshipStatus { active, applied, expired, revoked }

class ScholarshipProgram {
  const ScholarshipProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.discountPercent,
    required this.requirements,
    required this.slots,
    required this.slotsTaken,
  });

  final String id;
  final String name;
  final String description;
  final double discountPercent;
  final String requirements;
  final int slots;
  final int slotsTaken;

  bool get isFull => slotsTaken >= slots;

  factory ScholarshipProgram.fromJson(Map<String, dynamic> json) =>
      ScholarshipProgram(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        discountPercent: (json['discountPercent'] as num).toDouble(),
        requirements: json['requirements'] as String,
        slots: json['slots'] as int,
        slotsTaken: json['slotsTaken'] as int,
      );
}

class ScholarshipApplication {
  const ScholarshipApplication({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.scholarshipId,
    required this.scholarshipName,
    required this.status,
    required this.appliedAt,
    this.remarks,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String scholarshipId;
  final String scholarshipName;
  final ScholarshipStatus status;
  final DateTime appliedAt;
  final String? remarks;

  ScholarshipApplication copyWith({ScholarshipStatus? status, String? remarks}) =>
      ScholarshipApplication(
        id: id,
        studentId: studentId,
        studentName: studentName,
        scholarshipId: scholarshipId,
        scholarshipName: scholarshipName,
        status: status ?? this.status,
        appliedAt: appliedAt,
        remarks: remarks ?? this.remarks,
      );
}

// ---------------------------------------------------------------------------
// Installment Plan
// ---------------------------------------------------------------------------

enum InstallmentStatus { upcoming, paid, overdue }

class Installment {
  const Installment({
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidAt,
  });

  final DateTime dueDate;
  final double amount;
  final InstallmentStatus status;
  final DateTime? paidAt;

  Installment copyWith({InstallmentStatus? status, DateTime? paidAt}) =>
      Installment(
        dueDate: dueDate,
        amount: amount,
        status: status ?? this.status,
        paidAt: paidAt ?? this.paidAt,
      );
}

class InstallmentPlan {
  const InstallmentPlan({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.term,
    required this.totalAmount,
    required this.installments,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String term;
  final double totalAmount;
  final List<Installment> installments;

  double get totalPaid =>
      installments.where((i) => i.status == InstallmentStatus.paid).fold(0.0, (s, i) => s + i.amount);

  double get balance => (totalAmount - totalPaid).clamp(0, double.infinity);

  int get paidCount => installments.where((i) => i.status == InstallmentStatus.paid).length;
}

// ---------------------------------------------------------------------------
// Counseling Record
// ---------------------------------------------------------------------------

enum CounselingType { academic, personal, career, disciplinary }

extension CounselingTypeLabel on CounselingType {
  String get label {
    switch (this) {
      case CounselingType.academic:
        return 'Academic';
      case CounselingType.personal:
        return 'Personal';
      case CounselingType.career:
        return 'Career';
      case CounselingType.disciplinary:
        return 'Disciplinary';
    }
  }
}

class CounselingRecord {
  const CounselingRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.counselorName,
    required this.type,
    required this.notes,
    required this.sessionDate,
    this.followUpDate,
    this.isResolved = false,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String counselorName;
  final CounselingType type;
  final String notes;
  final DateTime sessionDate;
  final DateTime? followUpDate;
  final bool isResolved;

  CounselingRecord copyWith({bool? isResolved, DateTime? followUpDate}) =>
      CounselingRecord(
        id: id,
        studentId: studentId,
        studentName: studentName,
        counselorName: counselorName,
        type: type,
        notes: notes,
        sessionDate: sessionDate,
        followUpDate: followUpDate ?? this.followUpDate,
        isResolved: isResolved ?? this.isResolved,
      );
}

// ---------------------------------------------------------------------------
// Curriculum Checklist (Degree Audit)
// ---------------------------------------------------------------------------

enum ChecklistItemStatus { completed, inProgress, notTaken }

class CurriculumItem {
  const CurriculumItem({
    required this.subjectCode,
    required this.subjectTitle,
    required this.units,
    required this.yearLevel,
    required this.semester,
    required this.status,
    this.grade,
  });

  final String subjectCode;
  final String subjectTitle;
  final double units;
  final int yearLevel;
  final int semester;
  final ChecklistItemStatus status;
  final double? grade;
}

class CurriculumChecklist {
  const CurriculumChecklist({
    required this.studentId,
    required this.program,
    required this.totalUnitsRequired,
    required this.items,
  });

  final String studentId;
  final String program;
  final double totalUnitsRequired;
  final List<CurriculumItem> items;

  double get unitsCompleted => items
      .where((i) => i.status == ChecklistItemStatus.completed)
      .fold(0.0, (s, i) => s + i.units);

  double get unitsInProgress => items
      .where((i) => i.status == ChecklistItemStatus.inProgress)
      .fold(0.0, (s, i) => s + i.units);

  double get progressPercent =>
      totalUnitsRequired > 0 ? (unitsCompleted / totalUnitsRequired * 100).clamp(0, 100) : 0;

  int get completedCount => items.where((i) => i.status == ChecklistItemStatus.completed).length;
}

// ---------------------------------------------------------------------------
// Department Performance
// ---------------------------------------------------------------------------

class DepartmentPerformance {
  const DepartmentPerformance({
    required this.department,
    required this.totalStudents,
    required this.totalFaculty,
    required this.averageGpa,
    required this.passRate,
    required this.retentionRate,
    required this.failedStudents,
    required this.honorsStudents,
  });

  final String department;
  final int totalStudents;
  final int totalFaculty;
  final double averageGpa;
  final double passRate;
  final double retentionRate;
  final int failedStudents;
  final int honorsStudents;
}

// ---------------------------------------------------------------------------
// Graduation Evaluation
// ---------------------------------------------------------------------------

class GraduationEvaluation {
  const GraduationEvaluation({
    required this.studentId,
    required this.studentName,
    required this.program,
    required this.totalUnitsRequired,
    required this.unitsCompleted,
    required this.deficiencies,
    required this.isEligible,
    this.remarks,
  });

  final String studentId;
  final String studentName;
  final String program;
  final double totalUnitsRequired;
  final double unitsCompleted;

  /// List of unmet requirements (empty if fully eligible).
  final List<String> deficiencies;
  final bool isEligible;
  final String? remarks;
}

// ---------------------------------------------------------------------------
// Calendar Event
// ---------------------------------------------------------------------------

enum CalendarCategory { academic, exam, holiday, activity, deadline }

extension CalendarCategoryLabel on CalendarCategory {
  String get label {
    switch (this) {
      case CalendarCategory.academic:
        return 'Academic';
      case CalendarCategory.exam:
        return 'Exam';
      case CalendarCategory.holiday:
        return 'Holiday';
      case CalendarCategory.activity:
        return 'Activity';
      case CalendarCategory.deadline:
        return 'Deadline';
    }
  }
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    this.endDate,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final CalendarCategory category;

  bool get isMultiDay => endDate != null && endDate!.isAfter(date);

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
        category: CalendarCategory.values.byName(json['category'] as String),
      );
}

// ---------------------------------------------------------------------------
// User Settings
// ---------------------------------------------------------------------------

class UserSettings {
  const UserSettings({
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.darkMode,
    this.language = 'en',
  });

  final bool notificationsEnabled;
  final bool emailNotifications;

  /// null = system default
  final bool? darkMode;
  final String language;

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? darkMode,
    String? language,
  }) =>
      UserSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        darkMode: darkMode ?? this.darkMode,
        language: language ?? this.language,
      );
}

// ---------------------------------------------------------------------------
// Attendance Summary (for Faculty Analytics)
// ---------------------------------------------------------------------------

class AttendanceSummary {
  const AttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.totalSessions,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
  });

  final String studentId;
  final String studentName;
  final int totalSessions;
  final int present;
  final int absent;
  final int late;
  final int excused;

  double get attendanceRate =>
      totalSessions > 0 ? (present + late) / totalSessions * 100 : 0;
}

// ---------------------------------------------------------------------------
// Grade Distribution (for Faculty Analytics)
// ---------------------------------------------------------------------------

class GradeDistribution {
  const GradeDistribution({
    required this.sectionId,
    required this.subjectCode,
    required this.excellent,
    required this.good,
    required this.satisfactory,
    required this.passing,
    required this.failing,
    required this.incomplete,
  });

  final String sectionId;
  final String subjectCode;
  final int excellent;  // 1.00–1.50
  final int good;       // 1.51–2.00
  final int satisfactory; // 2.01–2.50
  final int passing;    // 2.51–3.00
  final int failing;    // 3.01–5.00
  final int incomplete;

  int get totalStudents => excellent + good + satisfactory + passing + failing + incomplete;
  double get passRate =>
      totalStudents > 0 ? (excellent + good + satisfactory + passing) / totalStudents * 100 : 0;
}

// ---------------------------------------------------------------------------
// Financial Report (for Accounting)
// ---------------------------------------------------------------------------

class FinancialReport {
  const FinancialReport({
    required this.period,
    required this.totalRevenue,
    required this.totalReceivables,
    required this.collectionRate,
    required this.revenueByMonth,
    required this.collectionsByMethod,
  });

  final String period;
  final double totalRevenue;
  final double totalReceivables;
  final double collectionRate;
  final Map<String, double> revenueByMonth;
  final Map<String, double> collectionsByMethod;
}
