import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/academic_models.dart';
import '../../models/financial_models.dart';
import '../../models/campus_models.dart';
import '../../models/audit_log.dart';
import '../../models/advanced_models.dart';

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
      id: 'P202300310',
      name: 'Carlos Mendoza',
      email: 'carlos.mendoza@pgpc.edu.ph',
      role: UserRole.student,
      loginId: 'P202300310',
    ),
    const AppUser(
      id: 'P202200055',
      name: 'Maria Clara Diaz',
      email: 'maria.diaz@pgpc.edu.ph',
      role: UserRole.student,
      loginId: 'P202200055',
    ),
    const AppUser(
      id: 'P202400102',
      name: 'Rafael Tan',
      email: 'rafael.tan@pgpc.edu.ph',
      role: UserRole.student,
      loginId: 'P202400102',
    ),
    const AppUser(
      id: 'P202300188',
      name: 'Sophia Ramos',
      email: 'sophia.ramos@pgpc.edu.ph',
      role: UserRole.student,
      loginId: 'P202300188',
    ),
    const AppUser(
      id: 'P202200033',
      name: 'Daniel Cruz',
      email: 'daniel.cruz@pgpc.edu.ph',
      role: UserRole.student,
      loginId: 'P202200033',
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
      id: 'u_fac_003',
      name: 'Prof. Eduardo Garcia',
      email: 'e.garcia@pgpc.edu.ph',
      role: UserRole.teacher,
      loginId: 'EMP-1091',
      department: 'College of Computing Studies',
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
    StudentProfile(
      studentId: 'P202300310',
      program: 'BS Information Technology',
      yearLevel: 2,
      blockSection: 'BSIT-2B',
    ),
    StudentProfile(
      studentId: 'P202200055',
      program: 'BS Information Technology',
      yearLevel: 4,
      blockSection: 'BSIT-4A',
      scholarshipLabel: 'Academic Excellence Awardee',
    ),
    StudentProfile(
      studentId: 'P202400102',
      program: 'BS Business Administration',
      yearLevel: 1,
      blockSection: 'BSBA-1A',
    ),
    StudentProfile(
      studentId: 'P202300188',
      program: 'BS Business Administration',
      yearLevel: 2,
      blockSection: 'BSBA-2A',
    ),
    StudentProfile(
      studentId: 'P202200033',
      program: 'BS Information Technology',
      yearLevel: 4,
      blockSection: 'BSIT-4A',
    ),
  ];

  final List<Subject> subjects = const [
    Subject(code: 'IT101', title: 'Introduction to Computing', units: 3),
    Subject(code: 'IT102', title: 'Computer Programming 1', units: 3, prerequisites: ['IT101']),
    Subject(code: 'IT201', title: 'Data Structures and Algorithms', units: 3, prerequisites: ['IT102']),
    Subject(code: 'IT202', title: 'Information Management', units: 3),
    Subject(code: 'IT203', title: 'Mobile Application Development', units: 3, prerequisites: ['IT201']),
    Subject(code: 'IT301', title: 'Software Engineering', units: 3, prerequisites: ['IT201']),
    Subject(code: 'IT302', title: 'Web Development', units: 3, prerequisites: ['IT102']),
    Subject(code: 'IT401', title: 'Capstone Project 1', units: 3, prerequisites: ['IT301']),
    Subject(code: 'IT402', title: 'Capstone Project 2', units: 3, prerequisites: ['IT401']),
    Subject(code: 'GE101', title: 'Purposive Communication', units: 3),
    Subject(code: 'GE102', title: 'Understanding the Self', units: 3),
    Subject(code: 'GE105', title: 'The Life and Works of Rizal', units: 3),
    Subject(code: 'MATH101', title: 'College Algebra', units: 3),
    Subject(code: 'MATH102', title: 'Discrete Mathematics', units: 3, prerequisites: ['MATH101']),
    Subject(code: 'IT250', title: 'Human-Computer Interaction', units: 3, isElective: true),
    Subject(code: 'IT260', title: 'Cloud Computing Fundamentals', units: 3, isElective: true),
    Subject(code: 'IT270', title: 'Cybersecurity Fundamentals', units: 3, isElective: true),
    Subject(code: 'BA301', title: 'Financial Management', units: 3),
    Subject(code: 'PE101', title: 'Physical Fitness 1', units: 2),
    Subject(code: 'PE201', title: 'Physical Fitness 2', units: 2, prerequisites: ['PE101']),
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
    Section(
      id: 'sec_it301_a',
      subjectCode: 'IT301',
      sectionLabel: 'BSIT-3A',
      facultyName: 'Prof. Eduardo Garcia',
      dayPattern: 'TTh',
      startTime: '08:00',
      endTime: '09:30',
      room: 'CCS Lab 3',
      slotsTotal: 35,
      slotsTaken: 30,
    ),
  ];

  final List<Grade> grades = [
    const Grade(subjectCode: 'IT101', subjectTitle: 'Intro to Computing', units: 3, term: 'A.Y. 2025–2026, 1st Semester', numericGrade: 1.50),
    const Grade(subjectCode: 'IT102', subjectTitle: 'Computer Programming 1', units: 3, term: 'A.Y. 2025–2026, 1st Semester', numericGrade: 1.75),
    const Grade(subjectCode: 'GE101', subjectTitle: 'Purposive Communication', units: 3, term: 'A.Y. 2025–2026, 2nd Semester', numericGrade: 1.75),
    const Grade(subjectCode: 'MATH101', subjectTitle: 'College Algebra', units: 3, term: 'A.Y. 2025–2026, 2nd Semester', numericGrade: 2.00),
    const Grade(subjectCode: 'PE101', subjectTitle: 'Physical Fitness 1', units: 2, term: 'A.Y. 2025–2026, 2nd Semester', numericGrade: 1.25),
    const Grade(subjectCode: 'GE102', subjectTitle: 'Understanding the Self', units: 3, term: 'A.Y. 2025–2026, 2nd Semester', numericGrade: 1.50),
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
    'P202300310': const TuitionLedger(
      studentId: 'P202300310',
      term: term,
      tuitionFee: 12500,
      miscFees: 2300,
      labFees: 1800,
      scholarshipDiscount: 0,
      totalPaid: 8300,
    ),
    'P202200055': const TuitionLedger(
      studentId: 'P202200055',
      term: term,
      tuitionFee: 12500,
      miscFees: 2300,
      labFees: 1800,
      scholarshipDiscount: 8000,
      totalPaid: 8600,
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
    Payment(
      id: 'pay_003',
      studentId: 'P202300310',
      studentName: 'Carlos Mendoza',
      amount: 8300,
      method: PaymentMethod.cash,
      receiptNumber: 'OR-2026-01038',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      recordedBy: 'Bea Fernandez',
    ),
    Payment(
      id: 'pay_004',
      studentId: 'P202200055',
      studentName: 'Maria Clara Diaz',
      amount: 8600,
      method: PaymentMethod.maya,
      receiptNumber: 'OR-2026-01040',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      recordedBy: 'Bea Fernandez',
    ),
    Payment(
      id: 'pay_005',
      studentId: 'P202300188',
      studentName: 'Sophia Ramos',
      amount: 4500,
      method: PaymentMethod.gcash,
      receiptNumber: 'OR-2026-01041',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
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
    const Enrollment(
      id: 'enr_004',
      studentId: 'P202300310',
      term: term,
      sectionIds: ['sec_it201_a', 'sec_it202_a'],
      status: EnrollmentStatus.enrolled,
    ),
    const Enrollment(
      id: 'enr_005',
      studentId: 'P202200055',
      term: term,
      sectionIds: ['sec_it301_a'],
      status: EnrollmentStatus.enrolled,
    ),
    const Enrollment(
      id: 'enr_006',
      studentId: 'P202400102',
      term: term,
      sectionIds: ['sec_ba301_a'],
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
    Announcement(
      id: 'ann_004',
      title: 'Faculty Evaluation Period Open',
      body: 'All students are required to complete faculty evaluations for their enrolled subjects this term. '
          'Access the evaluation form through Student Tools.',
      category: 'Academics',
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<PromotionalAnnouncement> promotionalAnnouncements = [
    PromotionalAnnouncement(
      id: 'promo_001',
      title: '🎓 PGPC Mobile App Now Available!',
      body: 'Download the official PGPC Campus App for instant access to grades, schedule, tuition, and announcements. Stay connected anywhere!',
      category: 'Promotion',
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
      backgroundColor: const Color(0xFF102A6D),
      textColor: Colors.white,
      actionLabel: 'Download Now',
      actionUrl: 'https://pgpc.edu.ph/app',
      iconCodePoint: Icons.download_rounded.codePoint,
      priority: 10,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 60)),
    ),
    PromotionalAnnouncement(
      id: 'promo_002',
      title: '🏆 Foundation Week 2026 - Register Now!',
      body: 'Join the sportsfest, talent night, and academic competitions. Open to all students. Limited slots available!',
      category: 'Events',
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
      backgroundColor: const Color(0xFFC62828),
      textColor: Colors.white,
      actionLabel: 'View Events',
      actionUrl: '/events/foundation-week',
      iconCodePoint: Icons.emoji_events_rounded.codePoint,
      priority: 8,
      startDate: DateTime.now().subtract(const Duration(days: 14)),
      endDate: DateTime.now().add(const Duration(days: 21)),
    ),
    PromotionalAnnouncement(
      id: 'promo_003',
      title: '💳 Pay Tuition Online - GCash & Maya Accepted',
      body: 'No more long queues! Pay your tuition fees securely through the app using GCash, Maya, or bank transfer. Fast and convenient.',
      category: 'Finance',
      postedAt: DateTime.now().subtract(const Duration(days: 3)),
      backgroundColor: const Color(0xFF2E7D32),
      textColor: Colors.white,
      actionLabel: 'Pay Now',
      actionUrl: '/tuition/pay',
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
      priority: 7,
      startDate: DateTime.now().subtract(const Duration(days: 60)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    ),
    PromotionalAnnouncement(
      id: 'promo_004',
      title: '📚 Library Extended Hours - Open Until 8PM',
      body: 'The campus library now extends its hours until 8:00 PM on weekdays. Perfect for late-night study sessions and research work.',
      category: 'Facilities',
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
      backgroundColor: const Color(0xFF00838F),
      textColor: Colors.white,
      actionLabel: 'Learn More',
      actionUrl: '/facilities/library',
      iconCodePoint: Icons.local_library_rounded.codePoint,
      priority: 5,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 30)),
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
      NotificationItem(
        id: 'ntf_003',
        title: 'Faculty evaluation open',
        body: 'Please evaluate your faculty for this semester through Student Tools.',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      NotificationItem(
        id: 'ntf_004',
        title: 'Document ready for pickup',
        body: 'Your Certificate of Enrollment is ready at the Registrar window.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
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
    'P202300212': const Clearance(
      studentId: 'P202300212',
      term: term,
      steps: [
        ClearanceStep(office: 'Library', cleared: true, clearedBy: 'Lib. Santos'),
        ClearanceStep(office: 'Laboratory', cleared: true, clearedBy: 'Eng. Torres'),
        ClearanceStep(office: 'Accounting', cleared: true, clearedBy: 'N. Ibarra'),
        ClearanceStep(office: 'Guidance', cleared: false),
      ],
    ),
    'P202200055': const Clearance(
      studentId: 'P202200055',
      term: term,
      steps: [
        ClearanceStep(office: 'Library', cleared: true, clearedBy: 'Lib. Santos'),
        ClearanceStep(office: 'Laboratory', cleared: true, clearedBy: 'Eng. Torres'),
        ClearanceStep(office: 'Accounting', cleared: true, clearedBy: 'N. Ibarra'),
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

  // ---------------------------------------------------------------------------
  // Advanced seed data
  // ---------------------------------------------------------------------------

  final List<ScholarshipProgram> scholarshipPrograms = const [
    ScholarshipProgram(
      id: 'sch_001',
      name: 'LGU Merit Scholarship',
      description: 'Full tuition discount for students from the municipality with a GPA of 1.75 or better.',
      discountPercent: 100,
      requirements: 'Must maintain a GPA of 1.75 or better. Must be a resident of Padre Garcia.',
      slots: 20,
      slotsTaken: 15,
    ),
    ScholarshipProgram(
      id: 'sch_002',
      name: 'Academic Excellence Award',
      description: '50% tuition discount for Dean\'s Listers.',
      discountPercent: 50,
      requirements: 'Must be on the Dean\'s List for the previous semester.',
      slots: 30,
      slotsTaken: 22,
    ),
    ScholarshipProgram(
      id: 'sch_003',
      name: 'CHED Tulong-Dunong',
      description: 'Government financial assistance for qualified students.',
      discountPercent: 75,
      requirements: 'Must come from a family with income below ₱400,000/year. Must be enrolled full-time.',
      slots: 50,
      slotsTaken: 48,
    ),
    ScholarshipProgram(
      id: 'sch_004',
      name: 'Student Assistant Program',
      description: 'Work-study program offering tuition reduction in exchange for campus service hours.',
      discountPercent: 25,
      requirements: '10 hours/week of campus service. Must maintain passing grades.',
      slots: 15,
      slotsTaken: 10,
    ),
  ];

  final List<ScholarshipApplication> scholarshipApplications = [
    ScholarshipApplication(
      id: 'sa_001',
      studentId: 'P202300147',
      studentName: 'Andrea Villanueva',
      scholarshipId: 'sch_001',
      scholarshipName: 'LGU Merit Scholarship',
      status: ScholarshipStatus.active,
      appliedAt: DateTime(2026, 6, 15),
    ),
    ScholarshipApplication(
      id: 'sa_002',
      studentId: 'P202200055',
      studentName: 'Maria Clara Diaz',
      scholarshipId: 'sch_002',
      scholarshipName: 'Academic Excellence Award',
      status: ScholarshipStatus.active,
      appliedAt: DateTime(2026, 7),
    ),
    ScholarshipApplication(
      id: 'sa_003',
      studentId: 'P202400089',
      studentName: 'Jasmine Reyes',
      scholarshipId: 'sch_003',
      scholarshipName: 'CHED Tulong-Dunong',
      status: ScholarshipStatus.applied,
      appliedAt: DateTime(2026, 7, 20),
    ),
    ScholarshipApplication(
      id: 'sa_004',
      studentId: 'P202300310',
      studentName: 'Carlos Mendoza',
      scholarshipId: 'sch_004',
      scholarshipName: 'Student Assistant Program',
      status: ScholarshipStatus.active,
      appliedAt: DateTime(2026, 8),
    ),
  ];

  final List<InstallmentPlan> installmentPlans = [
    InstallmentPlan(
      id: 'inst_001',
      studentId: 'P202300147',
      studentName: 'Andrea Villanueva',
      term: term,
      totalAmount: 10600,
      installments: [
        Installment(
          dueDate: DateTime(2026, 8, 15),
          amount: 3534,
          status: InstallmentStatus.paid,
          paidAt: DateTime(2026, 8, 12),
        ),
        Installment(
          dueDate: DateTime(2026, 9, 15),
          amount: 3533,
          status: InstallmentStatus.upcoming,
        ),
        Installment(
          dueDate: DateTime(2026, 10, 15),
          amount: 3533,
          status: InstallmentStatus.upcoming,
        ),
      ],
    ),
    InstallmentPlan(
      id: 'inst_002',
      studentId: 'P202400089',
      studentName: 'Jasmine Reyes',
      term: term,
      totalAmount: 15400,
      installments: [
        Installment(
          dueDate: DateTime(2026, 8, 15),
          amount: 5134,
          status: InstallmentStatus.overdue,
        ),
        Installment(
          dueDate: DateTime(2026, 9, 15),
          amount: 5133,
          status: InstallmentStatus.upcoming,
        ),
        Installment(
          dueDate: DateTime(2026, 10, 15),
          amount: 5133,
          status: InstallmentStatus.upcoming,
        ),
      ],
    ),
  ];

  final List<CounselingRecord> counselingRecords = [
    CounselingRecord(
      id: 'cr_001',
      studentId: 'P202300147',
      studentName: 'Andrea Villanueva',
      counselorName: 'Corazon Lim',
      type: CounselingType.academic,
      notes: 'Student expressed concern about managing workload with scholarship requirements. '
          'Discussed time management strategies and available tutoring resources.',
      sessionDate: DateTime.now().subtract(const Duration(days: 14)),
      followUpDate: DateTime.now().add(const Duration(days: 7)),
    ),
    CounselingRecord(
      id: 'cr_002',
      studentId: 'P202400089',
      studentName: 'Jasmine Reyes',
      counselorName: 'Corazon Lim',
      type: CounselingType.personal,
      notes: 'Student adjusting to college life. Discussed campus resources and support networks.',
      sessionDate: DateTime.now().subtract(const Duration(days: 7)),
      isResolved: true,
    ),
    CounselingRecord(
      id: 'cr_003',
      studentId: 'P202300310',
      studentName: 'Carlos Mendoza',
      counselorName: 'Corazon Lim',
      type: CounselingType.career,
      notes: 'Career planning session. Reviewed internship opportunities in web development. '
          'Student interested in pursuing mobile app development track.',
      sessionDate: DateTime.now().subtract(const Duration(days: 3)),
      followUpDate: DateTime.now().add(const Duration(days: 14)),
    ),
  ];

  final List<FacultyEvaluation> facultyEvaluations = [
    FacultyEvaluation(
      id: 'eval_001',
      studentId: 'P202300147',
      facultyName: 'Prof. Ramon Dela Cruz',
      sectionId: 'sec_it201_a',
      term: term,
      rating: 5,
      comment: 'Excellent professor. Explains concepts clearly and gives practical examples.',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    FacultyEvaluation(
      id: 'eval_002',
      studentId: 'P202300212',
      facultyName: 'Prof. Liza Marquez',
      sectionId: 'sec_ba301_a',
      term: term,
      rating: 4,
      comment: 'Very knowledgeable. Homework load is heavy but manageable.',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<CalendarEvent> calendarEvents = [
    CalendarEvent(
      id: 'cal_001',
      title: 'First Day of Classes',
      description: 'Regular classes begin for A.Y. 2026–2027, 1st Semester.',
      date: DateTime(2026, 8, 5),
      category: CalendarCategory.academic,
    ),
    CalendarEvent(
      id: 'cal_002',
      title: 'Preliminary Examinations',
      description: 'Prelim exams for all programs.',
      date: DateTime(2026, 9, 15),
      endDate: DateTime(2026, 9, 19),
      category: CalendarCategory.exam,
    ),
    CalendarEvent(
      id: 'cal_003',
      title: 'Foundation Week',
      description: 'PGPC Foundation Day celebration with sportsfest and cultural events.',
      date: DateTime(2026, 9, 22),
      endDate: DateTime(2026, 9, 26),
      category: CalendarCategory.activity,
    ),
    CalendarEvent(
      id: 'cal_004',
      title: 'Midterm Examinations',
      description: 'Midterm exams for all programs.',
      date: DateTime(2026, 10, 13),
      endDate: DateTime(2026, 10, 17),
      category: CalendarCategory.exam,
    ),
    CalendarEvent(
      id: 'cal_005',
      title: 'All Saints\' Day / All Souls\' Day',
      description: 'No classes.',
      date: DateTime(2026, 11),
      endDate: DateTime(2026, 11, 2),
      category: CalendarCategory.holiday,
    ),
    CalendarEvent(
      id: 'cal_006',
      title: 'Faculty Evaluation Deadline',
      description: 'Last day for students to submit faculty evaluations.',
      date: DateTime(2026, 11, 14),
      category: CalendarCategory.deadline,
    ),
    CalendarEvent(
      id: 'cal_007',
      title: 'Final Examinations',
      description: 'Final exams for all programs.',
      date: DateTime(2026, 12, 8),
      endDate: DateTime(2026, 12, 12),
      category: CalendarCategory.exam,
    ),
    CalendarEvent(
      id: 'cal_008',
      title: 'Christmas Break Begins',
      description: 'Holiday break starts. Classes resume January 5, 2027.',
      date: DateTime(2026, 12, 19),
      category: CalendarCategory.holiday,
    ),
    CalendarEvent(
      id: 'cal_009',
      title: 'Enrollment Deadline',
      description: 'Last day to settle enrollment balance for this semester.',
      date: DateTime(2026, 9, 30),
      category: CalendarCategory.deadline,
    ),
  ];
}

