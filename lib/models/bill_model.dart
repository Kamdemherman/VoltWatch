enum BillStatus { paid, unpaid, overdue, partial }

class BillModel {
  final String id;
  final String userId;
  final String billNumber;
  final double amountFcfa;
  final DateTime dueDate;
  final DateTime issueDate;
  final BillStatus status;
  final double consumptionKwh;
  final double serviceChargeFcfa;
  final double taxFcfa;
  final double lateFeeFcfa;
  final String? pdfUrl;
  final DateTime createdAt;

  BillModel({
    required this.id,
    required this.userId,
    required this.billNumber,
    required this.amountFcfa,
    required this.dueDate,
    required this.issueDate,
    required this.status,
    required this.consumptionKwh,
    required this.serviceChargeFcfa,
    required this.taxFcfa,
    required this.lateFeeFcfa,
    this.pdfUrl,
    required this.createdAt,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      billNumber: json['bill_number'] as String,
      amountFcfa: (json['amount_fcfa'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      issueDate: DateTime.parse(json['issue_date'] as String),
      status: _statusFromString(json['status'] as String),
      consumptionKwh: (json['consumption_kwh'] as num).toDouble(),
      serviceChargeFcfa: (json['service_charge_fcfa'] as num?)?.toDouble() ?? 0,
      taxFcfa: (json['tax_fcfa'] as num?)?.toDouble() ?? 0,
      lateFeeFcfa: (json['late_fee_fcfa'] as num?)?.toDouble() ?? 0,
      pdfUrl: json['pdf_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bill_number': billNumber,
      'amount_fcfa': amountFcfa,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'issue_date': issueDate.toIso8601String().split('T')[0],
      'status': _statusToString(status),
      'consumption_kwh': consumptionKwh,
      'service_charge_fcfa': serviceChargeFcfa,
      'tax_fcfa': taxFcfa,
      'late_fee_fcfa': lateFeeFcfa,
      'pdf_url': pdfUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static BillStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return BillStatus.paid;
      case 'unpaid':
        return BillStatus.unpaid;
      case 'overdue':
        return BillStatus.overdue;
      case 'partial':
        return BillStatus.partial;
      default:
        return BillStatus.unpaid;
    }
  }

  static String _statusToString(BillStatus status) {
    switch (status) {
      case BillStatus.paid:
        return 'paid';
      case BillStatus.unpaid:
        return 'unpaid';
      case BillStatus.overdue:
        return 'overdue';
      case BillStatus.partial:
        return 'partial';
    }
  }

  String get statusLabel {
    switch (status) {
      case BillStatus.paid:
        return 'Payée';
      case BillStatus.unpaid:
        return 'Non payée';
      case BillStatus.overdue:
        return 'En retard';
      case BillStatus.partial:
        return 'Partiellement payée';
    }
  }

  bool get isPaid => status == BillStatus.paid;
  bool get isUnpaid => status == BillStatus.unpaid;
  bool get isOverdue => status == BillStatus.overdue || DateTime.now().isAfter(dueDate);
  bool get isPartiallyPaid => status == BillStatus.partial;

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
  int get daysSinceIssue => DateTime.now().difference(issueDate).inDays;

  double get costPerKwh => consumptionKwh > 0 ? (amountFcfa - serviceChargeFcfa - taxFcfa) / consumptionKwh : 0;

  double get totalAmount => amountFcfa + lateFeeFcfa;

  BillModel copyWith({
    String? id,
    String? userId,
    String? billNumber,
    double? amountFcfa,
    DateTime? dueDate,
    DateTime? issueDate,
    BillStatus? status,
    double? consumptionKwh,
    double? serviceChargeFcfa,
    double? taxFcfa,
    double? lateFeeFcfa,
    String? pdfUrl,
    DateTime? createdAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      billNumber: billNumber ?? this.billNumber,
      amountFcfa: amountFcfa ?? this.amountFcfa,
      dueDate: dueDate ?? this.dueDate,
      issueDate: issueDate ?? this.issueDate,
      status: status ?? this.status,
      consumptionKwh: consumptionKwh ?? this.consumptionKwh,
      serviceChargeFcfa: serviceChargeFcfa ?? this.serviceChargeFcfa,
      taxFcfa: taxFcfa ?? this.taxFcfa,
      lateFeeFcfa: lateFeeFcfa ?? this.lateFeeFcfa,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum PaymentStatus { pending, completed, failed, cancelled }

enum PaymentMethod { mobileMoney, creditCard, bankTransfer, cash }

class PaymentModel {
  final String id;
  final String userId;
  final String billId;
  final double amountFcfa;
  final PaymentMethod paymentMethod;
  final String? paymentProvider;
  final String? transactionId;
  final PaymentStatus status;
  final DateTime paymentDate;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.billId,
    required this.amountFcfa,
    required this.paymentMethod,
    this.paymentProvider,
    this.transactionId,
    required this.status,
    required this.paymentDate,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      billId: json['bill_id'] as String,
      amountFcfa: (json['amount_fcfa'] as num).toDouble(),
      paymentMethod: _paymentMethodFromString(json['payment_method'] as String),
      paymentProvider: json['payment_provider'] as String?,
      transactionId: json['transaction_id'] as String?,
      status: _paymentStatusFromString(json['status'] as String),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bill_id': billId,
      'amount_fcfa': amountFcfa,
      'payment_method': _paymentMethodToString(paymentMethod),
      'payment_provider': paymentProvider,
      'transaction_id': transactionId,
      'status': _paymentStatusToString(status),
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static PaymentMethod _paymentMethodFromString(String method) {
    switch (method.toLowerCase()) {
      case 'mobile_money':
        return PaymentMethod.mobileMoney;
      case 'credit_card':
        return PaymentMethod.creditCard;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.mobileMoney;
    }
  }

  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.cash:
        return 'cash';
    }
  }

  static PaymentStatus _paymentStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  static String _paymentStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.creditCard:
        return 'Carte bancaire';
      case PaymentMethod.bankTransfer:
        return 'Virement bancaire';
      case PaymentMethod.cash:
        return 'Espèces';
    }
  }

  String get statusLabel {
    switch (status) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.completed:
        return 'Complété';
      case PaymentStatus.failed:
        return 'Échoué';
      case PaymentStatus.cancelled:
        return 'Annulé';
    }
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
}