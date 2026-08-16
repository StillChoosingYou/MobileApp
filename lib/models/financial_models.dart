enum PaymentMethod { cash, gcash, maya, bankTransfer, card }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.maya:
        return 'Maya';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.card:
        return 'Card';
    }
  }
}

enum PaymentStatus { verified, pending, refunded }

/// One payment against a student's ledger — recorded by a cashier, or
/// (once wired up) confirmed by a PayMongo webhook.
class Payment {

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        amount: (json['amount'] as num).toDouble(),
        method: PaymentMethod.values.byName(json['method'] as String),
        receiptNumber: json['receiptNumber'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        recordedBy: json['recordedBy'] as String,
        status: PaymentStatus.values.byName(json['status'] as String? ?? 'verified'),
        gatewayReference: json['gatewayReference'] as String?,
      );
  const Payment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.method,
    required this.receiptNumber,
    required this.timestamp,
    required this.recordedBy,
    this.status = PaymentStatus.verified,
    this.gatewayReference,
  });

  final String id;
  final String studentId;
  final String studentName;
  final double amount;
  final PaymentMethod method;
  final String receiptNumber;
  final DateTime timestamp;
  final String recordedBy;
  final PaymentStatus status;

  /// The PayMongo (or other gateway) source/payment intent id, when this
  /// payment came through the real gateway rather than an in-person cashier
  /// entry.
  final String? gatewayReference;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'amount': amount,
        'method': method.name,
        'receiptNumber': receiptNumber,
        'timestamp': timestamp.toIso8601String(),
        'recordedBy': recordedBy,
        'status': status.name,
        'gatewayReference': gatewayReference,
      };
}

/// The student's tuition standing for a term.
class TuitionLedger {

  factory TuitionLedger.fromJson(Map<String, dynamic> json) => TuitionLedger(
        studentId: json['studentId'] as String,
        term: json['term'] as String,
        tuitionFee: (json['tuitionFee'] as num).toDouble(),
        miscFees: (json['miscFees'] as num).toDouble(),
        labFees: (json['labFees'] as num).toDouble(),
        scholarshipDiscount: (json['scholarshipDiscount'] as num).toDouble(),
        totalPaid: (json['totalPaid'] as num).toDouble(),
      );
  const TuitionLedger({
    required this.studentId,
    required this.term,
    required this.tuitionFee,
    required this.miscFees,
    required this.labFees,
    required this.scholarshipDiscount,
    required this.totalPaid,
  });

  final String studentId;
  final String term;
  final double tuitionFee;
  final double miscFees;
  final double labFees;
  final double scholarshipDiscount;
  final double totalPaid;

  double get totalAssessed => tuitionFee + miscFees + labFees - scholarshipDiscount;
  double get balance => (totalAssessed - totalPaid).clamp(0, double.infinity);
  bool get isFullyPaid => balance <= 0.01;
}
