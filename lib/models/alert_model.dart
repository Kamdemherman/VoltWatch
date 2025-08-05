enum AlertType {
  consumptionSpike,
  billDue,
  paymentReminder,
  outageScheduled,
  customThreshold
}

enum ThresholdType { amountFcfa, consumptionKwh, percentage }

class AlertModel {
  final String id;
  final String userId;
  final AlertType alertType;
  final String title;
  final String message;
  final double? thresholdValue;
  final ThresholdType? thresholdType;
  final bool isActive;
  final bool isRead;
  final DateTime? triggeredAt;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.title,
    required this.message,
    this.thresholdValue,
    this.thresholdType,
    required this.isActive,
    required this.isRead,
    this.triggeredAt,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      alertType: _alertTypeFromString(json['alert_type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      thresholdValue: json['threshold_value']?.toDouble(),
      thresholdType: json['threshold_type'] != null 
          ? _thresholdTypeFromString(json['threshold_type'] as String)
          : null,
      isActive: json['is_active'] as bool,
      isRead: json['is_read'] as bool,
      triggeredAt: json['triggered_at'] != null 
          ? DateTime.parse(json['triggered_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'alert_type': _alertTypeToString(alertType),
      'title': title,
      'message': message,
      'threshold_value': thresholdValue,
      'threshold_type': thresholdType != null 
          ? _thresholdTypeToString(thresholdType!) 
          : null,
      'is_active': isActive,
      'is_read': isRead,
      'triggered_at': triggeredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static AlertType _alertTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'consumption_spike':
        return AlertType.consumptionSpike;
      case 'bill_due':
        return AlertType.billDue;
      case 'payment_reminder':
        return AlertType.paymentReminder;
      case 'outage_scheduled':
        return AlertType.outageScheduled;
      case 'custom_threshold':
        return AlertType.customThreshold;
      default:
        return AlertType.customThreshold;
    }
  }

  static String _alertTypeToString(AlertType type) {
    switch (type) {
      case AlertType.consumptionSpike:
        return 'consumption_spike';
      case AlertType.billDue:
        return 'bill_due';
      case AlertType.paymentReminder:
        return 'payment_reminder';
      case AlertType.outageScheduled:
        return 'outage_scheduled';
      case AlertType.customThreshold:
        return 'custom_threshold';
    }
  }

  static ThresholdType _thresholdTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'amount_fcfa':
        return ThresholdType.amountFcfa;
      case 'consumption_kwh':
        return ThresholdType.consumptionKwh;
      case 'percentage':
        return ThresholdType.percentage;
      default:
        return ThresholdType.amountFcfa;
    }
  }

  static String _thresholdTypeToString(ThresholdType type) {
    switch (type) {
      case ThresholdType.amountFcfa:
        return 'amount_fcfa';
      case ThresholdType.consumptionKwh:
        return 'consumption_kwh';
      case ThresholdType.percentage:
        return 'percentage';
    }
  }

  String get alertTypeLabel {
    switch (alertType) {
      case AlertType.consumptionSpike:
        return 'Pic de consommation';
      case AlertType.billDue:
        return 'Facture à échéance';
      case AlertType.paymentReminder:
        return 'Rappel de paiement';
      case AlertType.outageScheduled:
        return 'Coupure programmée';
      case AlertType.customThreshold:
        return 'Seuil personnalisé';
    }
  }

  String get alertTypeIcon {
    switch (alertType) {
      case AlertType.consumptionSpike:
        return '⚡';
      case AlertType.billDue:
        return '📄';
      case AlertType.paymentReminder:
        return '💳';
      case AlertType.outageScheduled:
        return '🔌';
      case AlertType.customThreshold:
        return '⚠️';
    }
  }

  String get thresholdTypeLabel {
    if (thresholdType == null) return '';
    switch (thresholdType!) {
      case ThresholdType.amountFcfa:
        return 'FCFA';
      case ThresholdType.consumptionKwh:
        return 'kWh';
      case ThresholdType.percentage:
        return '%';
    }
  }

  bool get isTriggered => triggeredAt != null;
  bool get isUnread => !isRead;

  int get daysSinceTriggered {
    if (triggeredAt == null) return 0;
    return DateTime.now().difference(triggeredAt!).inDays;
  }

  String get timeAgoString {
    if (triggeredAt == null) return 'Non déclenchée';
    
    final now = DateTime.now();
    final difference = now.difference(triggeredAt!);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  AlertModel copyWith({
    String? id,
    String? userId,
    AlertType? alertType,
    String? title,
    String? message,
    double? thresholdValue,
    ThresholdType? thresholdType,
    bool? isActive,
    bool? isRead,
    DateTime? triggeredAt,
    DateTime? createdAt,
  }) {
    return AlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      alertType: alertType ?? this.alertType,
      title: title ?? this.title,
      message: message ?? this.message,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      thresholdType: thresholdType ?? this.thresholdType,
      isActive: isActive ?? this.isActive,
      isRead: isRead ?? this.isRead,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum OutageStatus { scheduled, ongoing, completed, cancelled }

class OutageModel {
  final String id;
  final String region;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final String? reason;
  final OutageStatus status;
  final List<String> affectedAreas;
  final DateTime createdAt;

  OutageModel({
    required this.id,
    required this.region,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.reason,
    required this.status,
    required this.affectedAreas,
    required this.createdAt,
  });

  factory OutageModel.fromJson(Map<String, dynamic> json) {
    return OutageModel(
      id: json['id'] as String,
      region: json['region'] as String,
      scheduledStart: DateTime.parse(json['scheduled_start'] as String),
      scheduledEnd: DateTime.parse(json['scheduled_end'] as String),
      actualStart: json['actual_start'] != null 
          ? DateTime.parse(json['actual_start'] as String)
          : null,
      actualEnd: json['actual_end'] != null 
          ? DateTime.parse(json['actual_end'] as String)
          : null,
      reason: json['reason'] as String?,
      status: _outageStatusFromString(json['status'] as String),
      affectedAreas: (json['affected_areas'] as List<dynamic>)
          .map((area) => area as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'actual_start': actualStart?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'reason': reason,
      'status': _outageStatusToString(status),
      'affected_areas': affectedAreas,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static OutageStatus _outageStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return OutageStatus.scheduled;
      case 'ongoing':
        return OutageStatus.ongoing;
      case 'completed':
        return OutageStatus.completed;
      case 'cancelled':
        return OutageStatus.cancelled;
      default:
        return OutageStatus.scheduled;
    }
  }

  static String _outageStatusToString(OutageStatus status) {
    switch (status) {
      case OutageStatus.scheduled:
        return 'scheduled';
      case OutageStatus.ongoing:
        return 'ongoing';
      case OutageStatus.completed:
        return 'completed';
      case OutageStatus.cancelled:
        return 'cancelled';
    }
  }

  String get statusLabel {
    switch (status) {
      case OutageStatus.scheduled:
        return 'Programmée';
      case OutageStatus.ongoing:
        return 'En cours';
      case OutageStatus.completed:
        return 'Terminée';
      case OutageStatus.cancelled:
        return 'Annulée';
    }
  }

  bool get isScheduled => status == OutageStatus.scheduled;
  bool get isOngoing => status == OutageStatus.ongoing;
  bool get isCompleted => status == OutageStatus.completed;
  bool get isCancelled => status == OutageStatus.cancelled;

  Duration get scheduledDuration => scheduledEnd.difference(scheduledStart);
  Duration? get actualDuration => actualEnd != null && actualStart != null 
      ? actualEnd!.difference(actualStart!)
      : null;

  bool get isUpcoming => isScheduled && DateTime.now().isBefore(scheduledStart);
  bool get shouldBeOngoing => DateTime.now().isAfter(scheduledStart) && 
      DateTime.now().isBefore(scheduledEnd);

  String get affectedAreasString => affectedAreas.join(', ');
}