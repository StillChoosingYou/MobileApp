import '../../models/app_user.dart';
import '../../models/academic_models.dart';
import '../../models/financial_models.dart';
import '../../models/campus_models.dart';
import '../../models/audit_log.dart';

/// One shared, mutable seed so every mock repository sees the same "world" —
/// e.g. a payment the Cashier records shows up in the Student's tuition
/// ledger in the same demo session.
///
/// This is intentionally simple (plain lists, linear search) — it's a demo
/// data layer, not a database. Swap in the Firebase repositories for real
/// persistence.
class MockSeedData {
  MockSeedData._();
  static final MockSeedData instance = MockSeedData._();

  static const term = 'A.Y. 2026–2027, 1st Semester';

  final List<AppUser> users = [
    const AppUser(
      id: 'P202300147',
      name: 'Andrea Villanueva',
      email: 'andrea.villanueva@pgpc.edu.ph',
      role: UserRole.student,
      loginId: 'P202300147',
    ),
    const AppUser(
      id: 'P202300212',
      name: 'Miguel Santos',
      email: 'miguel.santos@pgpc.edu.ph',
      role: UserRole.student,
      loginId: 'P202300212',
    ),
    const AppUser(
      id: 'P202400089',
      name: 'Jasmine Reyes',
      email: 'jasmine.reyes@pgpc.edu.ph',
      role: UserRole.student,
      loginId: 'P202400089',
    ),
    const AppUser(
      id: 'u_fac_001',
      name: 'Prof. Ramon Dela Cruz',
      email: 'r.delacruz@pgpc.edu.ph',
      role: UserRole.teacher,
      loginId: 'EMP-1042',
      department: 'College of Computing Studies',
    ),
    const AppUser(
      id: 'u_fac_002',
      name: 'Prof. Liza Marquez',
      email: 'l.marquez@pgpc.edu.ph',
      role: UserRole.teacher,
      loginId: 'EMP-1077',
      department: 'College of Business Administration',
    ),
    const AppUser(
      id: 'u_reg_001',
      name: 'Evelyn Aquino',
      email: 'e.aquino@pgpc.edu.ph',
      role: UserRole.registrar,
      loginId: 'EMP-0501',
      department: 'Office of the Registrar',
    ),
    const AppUser(
      id: 'u_cas_001',
      name: 'Bea Fernandez',
      email: 'b.fernandez@pgpc.edu.ph',
      role: UserRole.cashier,
      loginId: 'EMP-0602',
      department: 'Cashier',
    ),
    const AppUser(
      id: 'u_acc_001',
      name: 'Noel Ibarra',
      email: 'n.ibarra@pgpc.edu.ph',
      role: UserRole.accounting,
      loginId: 'EMP-0611',
      department: 'Accounting',
    ),
    const AppUser(
      id: 'u_gui_001',
      name: 'Corazon Lim',
      email: 'c.lim@pgpc.edu.ph',
      role: UserRole.guidance,
      loginId: 'EMP-0705',
      department: 'Guidance Office',
    ),
    const AppUser(
      id: 'u_dh_001',
      name: 'Dr. Arnel Bautista',
      email: 'a.bautista@pgpc.edu.ph',
      role: UserRole.deptHead,
      loginId: 'EMP-0210',
      department: 'College of Computing Studies',
    ),
    const AppUser(
      id: 'u_dean_001',
      name: 'Dr. Teresita Ocampo',
      email: 't.ocampo@pgpc.edu.ph',
      role: UserRole.dean,
      loginId: 'EMP-0110',
      department: "Dean's Office",
    ),
    const AppUser(
      id: 'u_admin_001',
      name: 'Kevin Mercado',
      email: 'k.mercado@pgpc.edu.ph',
      role: UserRole.admin,
      loginId: 'EMP-0001',
      department: 'MIS / Admin',
    ),
  ];

  final List<StudentProfile> studentProfiles = const [
    StudentProfile(
      studentId: 'P202300147',
      program: 'BS Information Technology',
      yearLevel: 2,
      blockSection: 'BSIT-2A',
      scholarshipLabel: 'LGU Merit Scholar',
    ),
    StudentProfile(
      studentId: 'P202300212',
      program: 'BS Business Administration',
      yearLevel: 3,
      blockSection: 'BSBA-3B',
    ),
    StudentProfile(
      studentId: 'P202400089',
      program: 'BS Information Technology',
      yearLevel: 1,
      blockSection: 'BSIT-1C',
    ),
  ];

  final List<Subject> subjects = const [
    Subject(code: 'IT201', title: 'Data Structures and Algorithms', units: 3),
    Subject(code: 'IT202', title: 'Information Management', units: 3),
    Subject(code: 'IT203', title: 'Mobile Application Development', units: 3, prerequisites: ['IT201']),
    Subject(code: 'GE105', title: 'The Life and Works of Rizal', units: 3),
    Subject(code: 'IT250', title: 'Human-Computer Interaction', units: 3, isElective: true),
    Subject(code: 'IT260', title: 'Cloud Computing Fundamentals', units: 3, isElective: true),
    Subject(code: 'BA301', title: 'Financial Management', units: 3),
    Subject(code: 'PE201', title: 'Physical Fitness', units: 2),
  ];

  final List<Section> sections = const [
    Section(
      id: 'sec_it201_a',
      subjectCode: 'IT201',
      sectionLabel: 'BSIT-2A',
      facultyName: 'Prof. Ramon Dela Cruz',
      dayPattern: 'MWF',
      startTime: '08:00',
      endTime: '09:00',
      room: 'CCS Lab 1',
      slotsTotal: 40,
      slotsTaken: 38,
    ),
    Section(
      id: 'sec_it202_a',
      subjectCode: 'IT202',
      sectionLabel: 'BSIT-2A',
      facultyName: 'Prof. Ramon Dela Cruz',
      dayPattern: 'TTh',
      startTime: '09:30',
      endTime: '11:00',
      room: 'Room 204',
      slotsTotal: 40,
      slotsTaken: 40,
    ),
    Section(
      id: 'sec_ge105_a',
      subjectCode: 'GE105',
      sectionLabel: 'BSIT-2A',
      facultyName: 'Prof. Liza Marquez',
      dayPattern: 'MWF',
      startTime: '09:00',
      endTime: '10:00',
      room: 'Room 110',
      slotsTotal: 45,
      slotsTaken: 30,
    ),
    Section(
      id: 'sec_it203_a',
      subjectCode: 'IT203',
      sectionLabel: 'BSIT-2A',
      facultyName: 'Prof. Ramon Dela Cruz',
      dayPattern: 'TTh',
      startTime: '13:00',
      endTime: '14:30',
      room: 'CCS Lab 2',
      slotsTotal: 35,
      slotsTaken: 20,
    ),
    Section(
      id: 'sec_ba301_a',
      subjectCode: 'BA301',
      sectionLabel: 'BSBA-3B',
      facultyName: 'Prof. Liza Marquez',
      dayPattern: 'MWF',
      startTime: '10:00',
      endTime: '11:00',
      room: 'Room 305',
      slotsTotal: 40,
      slotsTaken: 33,
    ),
  ];

  final List<Grade> grades = [
    const Grade(subjectCode: 'IT101', subjectTitle: 'Intro to Computing', units: 3, term: 'A.Y. 2025–2026, 2nd Semester', numericGrade: 1.50),
    const Grade(subjectCode: 'GE101', subjectTitle: 'Purposive Communication', units: 3, term: 'A.Y. 2025–2026, 2nd Semester', numericGrade: 1.75),
    const Grade(subjectCode: 'MATH101', subjectTitle: 'College Algebra', units: 3, term: 'A.Y. 2025–2026, 2nd Semester', numericGrade: 2.00),
    const Grade(subjectCode: 'PE101', subjectTitle: 'Physical Fitness 1', units: 2, term: 'A.Y. 2025–2026, 2nd Semester', numericGrade: 1.25),
  ];

  final Map<String, TuitionLedger> ledgers = {
    'P202300147': const TuitionLedger(
      studentId: 'P202300147',
      term: term,
      tuitionFee: 12500,
      miscFees: 2300,
      labFees: 1800,
      scholarshipDiscount: 6000,
      totalPaid: 5000,
    ),
    'P202300212': const TuitionLedger(
      studentId: 'P202300212',
      term: term,
      tuitionFee: 13800,
      miscFees: 2300,
      labFees: 900,
      scholarshipDiscount: 0,
      totalPaid: 17000,
    ),
    'P202400089': const TuitionLedger(
      studentId: 'P202400089',
      term: term,
      tuitionFee: 11800,
      miscFees: 2100,
      labFees: 1500,
      scholarshipDiscount: 0,
      totalPaid: 0,
    ),
  };

  final List<Payment> payments = [
    Payment(
      id: 'pay_001',
      studentId: 'P202300147',
      studentName: 'Andrea Villanueva',
      amount: 5000,
      method: PaymentMethod.gcash,
      receiptNumber: 'OR-2026-01044',
      timestamp: DateTime.now().subtract(const Duration(days: 12)),
      recordedBy: 'Bea Fernandez',
    ),
    Payment(
      id: 'pay_002',
      studentId: 'P202300212',
      studentName: 'Miguel Santos',
      amount: 17000,
      method: PaymentMethod.bankTransfer,
      receiptNumber: 'OR-2026-01012',
      timestamp: DateTime.now().subtract(const Duration(days: 30)),
      recordedBy: 'Bea Fernandez',
    ),
  ];

  final List<Enrollment> enrollments = [
    const Enrollment(
      id: 'enr_001',
      studentId: 'P202300147',
      term: term,
      sectionIds: ['sec_it201_a', 'sec_it202_a', 'sec_ge105_a', 'sec_it203_a'],
      status: EnrollmentStatus.enrolled,
    ),
    const Enrollment(
      id: 'enr_002',
      studentId: 'P202300212',
      term: term,
      sectionIds: ['sec_ba301_a'],
      status: EnrollmentStatus.enrolled,
    ),
    const Enrollment(
      id: 'enr_003',
      studentId: 'P202400089',
      term: term,
      sectionIds: ['sec_it201_a'],
      status: EnrollmentStatus.pending,
    ),
  ];

  final List<Announcement> announcements = [
    Announcement(
      id: 'ann_001',
      title: 'Enrollment for 2nd Semester Now Open',
      body:
          'Continuing students may proceed with online enrollment through the Registrar module. '
          'Please settle at least the down payment to confirm your slot.',
      category: 'Enrollment',
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Announcement(
      id: 'ann_002',
      title: 'Midterm Examination Schedule Posted',
      body: 'Check your subject schedule for the exact room and seat plan for midterms.',
      category: 'Academics',
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Announcement(
      id: 'ann_003',
      title: 'Foundation Week Activities',
      body: 'Join the sportsfest and talent night. Details posted at the student affairs bulletin.',
      category: 'Campus Life',
      postedAt: DateTime.now().subtract(const Duration(days: 9)),
    ),
  ];

  final Map<String, List<NotificationItem>> notifications = {
    'P202300147': [
      NotificationItem(
        id: 'ntf_001',
        title: 'Payment received',
        body: 'Your GCash payment of ₱5,000 was recorded.',
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
        read: true,
      ),
      NotificationItem(
        id: 'ntf_002',
        title: 'Tuition deadline approaching',
        body: 'Settle your remaining balance before the midterm deadline.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  };

  final Map<String, List<DocumentRequest>> documentRequests = {
    'P202300147': [
      DocumentRequest(
        id: 'doc_001',
        studentId: 'P202300147',
        type: DocumentType.certificateOfEnrollment,
        purpose: 'Scholarship requirement',
        requestedAt: DateTime.now().subtract(const Duration(days: 4)),
        status: RequestStatus.ready,
      ),
    ],
  };

  final Map<String, Clearance> clearances = {
    'P202300147': const Clearance(
      studentId: 'P202300147',
      term: term,
      steps: [
        ClearanceStep(office: 'Library', cleared: true, clearedBy: 'Lib. Santos'),
        ClearanceStep(office: 'Laboratory', cleared: true, clearedBy: 'Eng. Torres'),
        ClearanceStep(office: 'Accounting', cleared: false),
        ClearanceStep(office: 'Guidance', cleared: true, clearedBy: 'C. Lim'),
      ],
    ),
  };

  final List<AuditLogEntry> auditLog = [
    AuditLogEntry(
      id: 'log_001',
      actor: 'Evelyn Aquino',
      action: 'Approved enrollment',
      target: 'enr_002 — Miguel Santos',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AuditLogEntry(
      id: 'log_002',
      actor: 'Bea Fernandez',
      action: 'Recorded payment',
      target: 'pay_001 — ₱5,000 GCash',
      timestamp: DateTime.now().subtract(const Duration(days: 12)),
    ),
    AuditLogEntry(
      id: 'log_003',
      actor: 'Kevin Mercado',
      action: 'Deactivated account',
      target: 'P202100099',
      timestamp: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  int _queueCounter = 3;
  final Map<QueueOffice, List<QueueTicket>> queues = {
    QueueOffice.registrar: [],
    QueueOffice.accounting: [],
    QueueOffice.cashier: [],
    QueueOffice.guidance: [],
  };

  int nextQueueNumber() => _queueCounter++;

  final List<VisitorLog> visitorLogs = [];
  final List<LostFoundItem> lostFoundItems = [
    LostFoundItem(
      id: 'lf_001',
      isFound: true,
      itemName: 'Black umbrella',
      description: 'Found near the covered walk after the rain yesterday.',
      location: 'Covered Walk, near Library',
      reportedBy: 'Security Guard on duty',
      reportedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
  final List<Appointment> appointments = [];
}
