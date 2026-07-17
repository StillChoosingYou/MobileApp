/// Every role the source spec calls out. Order here also drives the
/// role-select screen.
enum UserRole {
  student,
  teacher,
  registrar,
  accounting,
  cashier,
  guidance,
  deptHead,
  dean,
  admin;

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Faculty';
      case UserRole.registrar:
        return 'Registrar';
      case UserRole.accounting:
        return 'Accounting';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.guidance:
        return 'Guidance Counselor';
      case UserRole.deptHead:
        return 'Department Head';
      case UserRole.dean:
        return 'Dean';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  /// True for the back-office roles that share the simpler "role dashboard"
  /// shell instead of a bespoke bottom-nav shell.
  bool get usesGenericDashboard =>
      this == UserRole.accounting ||
      this == UserRole.guidance ||
      this == UserRole.deptHead ||
      this == UserRole.dean;

  static UserRole fromName(String name) =>
      UserRole.values.firstWhere((r) => r.name == name, orElse: () => UserRole.student);
}

/// The authenticated identity, independent of the domain-specific profile
/// (a Student's grades, a Faculty's class list, etc. live in their own
/// models and are looked up by [id]).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.loginId,
    this.photoUrl,
    this.department,
    this.biometricEnabled = false,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// The student number / employee ID they log in with — distinct from the
  /// internal Firestore/Hive [id].
  final String loginId;
  final String? photoUrl;
  final String? department;
  final bool biometricEnabled;

  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? department,
    bool? biometricEnabled,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role,
      loginId: loginId,
      photoUrl: photoUrl ?? this.photoUrl,
      department: department ?? this.department,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'loginId': loginId,
        'photoUrl': photoUrl,
        'department': department,
        'biometricEnabled': biometricEnabled,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRole.fromName(json['role'] as String),
        loginId: json['loginId'] as String,
        photoUrl: json['photoUrl'] as String?,
        department: json['department'] as String?,
        biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      );
}
