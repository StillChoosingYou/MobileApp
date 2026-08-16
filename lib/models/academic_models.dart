/// A catalog subject, independent of who teaches it or when.
class Subject {

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        code: json['code'] as String,
        title: json['title'] as String,
        units: (json['units'] as num).toDouble(),
        prerequisites: List<String>.from(json['prerequisites'] as List? ?? const []),
        isElective: json['isElective'] as bool? ?? false,
      );
  const Subject({
    required this.code,
    required this.title,
    required this.units,
    this.prerequisites = const [],
    this.isElective = false,
  });

  final String code;
  final String title;
  final double units;
  final List<String> prerequisites;
  final bool isElective;

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'units': units,
        'prerequisites': prerequisites,
        'isElective': isElective,
      };
}

/// One offered class: a Subject taught by someone, at a time, in a room.
class Section {

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        id: json['id'] as String,
        subjectCode: json['subjectCode'] as String,
        sectionLabel: json['sectionLabel'] as String,
        facultyName: json['facultyName'] as String,
        dayPattern: json['dayPattern'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        room: json['room'] as String,
        slotsTotal: json['slotsTotal'] as int,
        slotsTaken: json['slotsTaken'] as int,
      );
  const Section({
    required this.id,
    required this.subjectCode,
    required this.sectionLabel,
    required this.facultyName,
    required this.dayPattern,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.slotsTotal,
    required this.slotsTaken,
  });

  final String id;
  final String subjectCode;
  final String sectionLabel;
  final String facultyName;

  /// e.g. "MWF" or "TTh"
  final String dayPattern;

  /// 24h "HH:mm"
  final String startTime;
  final String endTime;
  final String room;
  final int slotsTotal;
  final int slotsTaken;

  bool get isFull => slotsTaken >= slotsTotal;

  /// True if [other] overlaps in both days and time — used by the smart
  /// enrollment conflict check.
  bool conflictsWith(Section other) {
    final sharesDay = dayPattern.split('').any((d) => other.dayPattern.contains(d));
    if (!sharesDay) return false;
    final aStart = _minutes(startTime);
    final aEnd = _minutes(endTime);
    final bStart = _minutes(other.startTime);
    final bEnd = _minutes(other.endTime);
    return aStart < bEnd && bStart < aEnd;
  }

  static int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectCode': subjectCode,
        'sectionLabel': sectionLabel,
        'facultyName': facultyName,
        'dayPattern': dayPattern,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'slotsTotal': slotsTotal,
        'slotsTaken': slotsTaken,
      };
}

enum EnrollmentStatus { pending, approved, enrolled, rejected }

/// A student's enrollment in one term, holding the sections they're taking.
class Enrollment {

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        term: json['term'] as String,
        sectionIds: List<String>.from(json['sectionIds'] as List? ?? const []),
        status: EnrollmentStatus.values.byName(json['status'] as String),
        remarks: json['remarks'] as String?,
      );
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.term,
    required this.sectionIds,
    required this.status,
    this.remarks,
  });

  final String id;
  final String studentId;
  final String term;
  final List<String> sectionIds;
  final EnrollmentStatus status;
  final String? remarks;

  Enrollment copyWith({EnrollmentStatus? status, String? remarks}) => Enrollment(
        id: id,
        studentId: studentId,
        term: term,
        sectionIds: sectionIds,
        status: status ?? this.status,
        remarks: remarks ?? this.remarks,
      );
}

/// A final grade for one subject in one term.
/// Uses the 1.00 (highest) – 5.00 (failing) scale common across Philippine
/// colleges; 3.00 is the usual passing threshold, 5.00 is a failure, "INC"
/// is represented as a null [numericGrade] with [isIncomplete] = true.
class Grade {

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        subjectCode: json['subjectCode'] as String,
        subjectTitle: json['subjectTitle'] as String,
        units: (json['units'] as num).toDouble(),
        term: json['term'] as String,
        numericGrade: (json['numericGrade'] as num?)?.toDouble(),
        isIncomplete: json['isIncomplete'] as bool? ?? false,
      );
  const Grade({
    required this.subjectCode,
    required this.subjectTitle,
    required this.units,
    required this.term,
    this.numericGrade,
    this.isIncomplete = false,
  });

  final String subjectCode;
  final String subjectTitle;
  final double units;
  final String term;
  final double? numericGrade;
  final bool isIncomplete;

  String get display => isIncomplete ? 'INC' : (numericGrade?.toStringAsFixed(2) ?? '—');
}

enum AttendanceStatus { present, absent, late, excused }

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.sectionId,
    required this.date,
    required this.status,
  });

  final String id;
  final String studentId;
  final String sectionId;
  final DateTime date;
  final AttendanceStatus status;
}

/// Academic-program details for a Student — kept separate from [AppUser]
/// since Faculty/Registrar/etc. don't have a program or year level.
class StudentProfile {

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        studentId: json['studentId'] as String,
        program: json['program'] as String,
        yearLevel: json['yearLevel'] as int,
        blockSection: json['blockSection'] as String,
        scholarshipLabel: json['scholarshipLabel'] as String?,
      );
  const StudentProfile({
    required this.studentId,
    required this.program,
    required this.yearLevel,
    required this.blockSection,
    this.scholarshipLabel,
  });

  final String studentId;
  final String program;
  final int yearLevel;
  final String blockSection;

  /// e.g. "LGU Merit Scholar" — null if not on a scholarship.
  final String? scholarshipLabel;
}
