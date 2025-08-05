class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String? eneoClientId;
  final String? fullName;
  final String? meterAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.eneoClientId,
    this.fullName,
    this.meterAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      eneoClientId: json['eneo_client_id'] as String?,
      fullName: json['full_name'] as String?,
      meterAddress: json['meter_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'eneo_client_id': eneoClientId,
      'full_name': fullName,
      'meter_address': meterAddress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? eneoClientId,
    String? fullName,
    String? meterAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      eneoClientId: eneoClientId ?? this.eneoClientId,
      fullName: fullName ?? this.fullName,
      meterAddress: meterAddress ?? this.meterAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserPreferences {
  final String id;
  final String userId;
  final double? monthlyBudgetFcfa;
  final int consumptionAlertPercentage;
  final double? customThresholdFcfa;
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSmsNotifications;
  final String preferredLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferences({
    required this.id,
    required this.userId,
    this.monthlyBudgetFcfa,
    required this.consumptionAlertPercentage,
    this.customThresholdFcfa,
    required this.enablePushNotifications,
    required this.enableEmailNotifications,
    required this.enableSmsNotifications,
    required this.preferredLanguage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      monthlyBudgetFcfa: json['monthly_budget_fcfa']?.toDouble(),
      consumptionAlertPercentage: json['consumption_alert_percentage'] as int,
      customThresholdFcfa: json['custom_threshold_fcfa']?.toDouble(),
      enablePushNotifications: json['enable_push_notifications'] as bool,
      enableEmailNotifications: json['enable_email_notifications'] as bool,
      enableSmsNotifications: json['enable_sms_notifications'] as bool,
      preferredLanguage: json['preferred_language'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'monthly_budget_fcfa': monthlyBudgetFcfa,
      'consumption_alert_percentage': consumptionAlertPercentage,
      'custom_threshold_fcfa': customThresholdFcfa,
      'enable_push_notifications': enablePushNotifications,
      'enable_email_notifications': enableEmailNotifications,
      'enable_sms_notifications': enableSmsNotifications,
      'preferred_language': preferredLanguage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}