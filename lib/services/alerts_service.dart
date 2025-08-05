import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voltwatch/supabase/supabase_config.dart';
import 'package:voltwatch/models/alert_model.dart';

class AlertsService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Get alerts
  static Future<List<AlertModel>> getAlerts({
    AlertType? type,
    bool? isActive,
    bool? isRead,
    int? limit,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final queryBuilder = _client
          .from('alerts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (limit != null) {
        queryBuilder.limit(limit);
      }

      final response = await queryBuilder;
      var filteredData = response as List<dynamic>;
      
      // Apply filters in code
      if (type != null) {
        filteredData = filteredData.where((item) => 
            item['alert_type'] == _alertTypeToString(type)).toList();
      }
      
      if (isActive != null) {
        filteredData = filteredData.where((item) => 
            item['is_active'] == isActive).toList();
      }
      
      if (isRead != null) {
        filteredData = filteredData.where((item) => 
            item['is_read'] == isRead).toList();
      }
      
      return filteredData
          .map((json) => AlertModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des alertes: $e');
    }
  }

  // Get unread alerts
  static Future<List<AlertModel>> getUnreadAlerts() async {
    return await getAlerts(isRead: false, isActive: true);
  }

  // Get active alerts
  static Future<List<AlertModel>> getActiveAlerts() async {
    return await getAlerts(isActive: true);
  }

  // Create alert
  static Future<AlertModel> createAlert({
    required AlertType alertType,
    required String title,
    required String message,
    double? thresholdValue,
    ThresholdType? thresholdType,
    bool isActive = true,
    DateTime? triggeredAt,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final response = await _client
          .from('alerts')
          .insert({
            'user_id': user.id,
            'alert_type': _alertTypeToString(alertType),
            'title': title,
            'message': message,
            'threshold_value': thresholdValue,
            'threshold_type': thresholdType != null 
                ? _thresholdTypeToString(thresholdType)
                : null,
            'is_active': isActive,
            'is_read': false,
            'triggered_at': triggeredAt?.toIso8601String(),
          })
          .select()
          .single();

      return AlertModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'alerte: $e');
    }
  }

  // Mark alert as read
  static Future<AlertModel> markAlertAsRead(String alertId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final response = await _client
          .from('alerts')
          .update({'is_read': true})
          .eq('id', alertId)
          .eq('user_id', user.id)
          .select()
          .single();

      return AlertModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors du marquage de l\'alerte: $e');
    }
  }

  // Mark all alerts as read
  static Future<void> markAllAlertsAsRead() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      await _client
          .from('alerts')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Erreur lors du marquage des alertes: $e');
    }
  }

  // Deactivate alert
  static Future<AlertModel> deactivateAlert(String alertId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final response = await _client
          .from('alerts')
          .update({'is_active': false})
          .eq('id', alertId)
          .eq('user_id', user.id)
          .select()
          .single();

      return AlertModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la désactivation de l\'alerte: $e');
    }
  }

  // Delete alert
  static Future<void> deleteAlert(String alertId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      await _client
          .from('alerts')
          .delete()
          .eq('id', alertId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'alerte: $e');
    }
  }

  // Get outages
  static Future<List<OutageModel>> getOutages({
    String? region,
    OutageStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryBuilder = _client
          .from('outages')
          .select()
          .order('scheduled_start', ascending: true);

      if (limit != null) {
        queryBuilder.limit(limit);
      }

      final response = await queryBuilder;
      var filteredData = response as List<dynamic>;
      
      // Apply filters in code
      if (region != null) {
        filteredData = filteredData.where((item) => 
            item['region'] == region).toList();
      }
      
      if (status != null) {
        filteredData = filteredData.where((item) => 
            item['status'] == _outageStatusToString(status)).toList();
      }
      
      if (startDate != null) {
        filteredData = filteredData.where((item) {
          final scheduledStart = DateTime.parse(item['scheduled_start'] as String);
          return !scheduledStart.isBefore(startDate);
        }).toList();
      }
      
      if (endDate != null) {
        filteredData = filteredData.where((item) {
          final scheduledEnd = DateTime.parse(item['scheduled_end'] as String);
          return !scheduledEnd.isAfter(endDate);
        }).toList();
      }
      
      return filteredData
          .map((json) => OutageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des coupures: $e');
    }
  }

  // Get upcoming outages
  static Future<List<OutageModel>> getUpcomingOutages({String? region}) async {
    return await getOutages(
      region: region,
      status: OutageStatus.scheduled,
      startDate: DateTime.now(),
    );
  }

  // Get current outages
  static Future<List<OutageModel>> getCurrentOutages({String? region}) async {
    return await getOutages(
      region: region,
      status: OutageStatus.ongoing,
    );
  }

  // Check and create consumption spike alerts
  static Future<void> checkConsumptionSpikeAlerts(double currentConsumption, double averageConsumption) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    try {
      // Get user preferences to check threshold
      final preferencesResponse = await _client
          .from('user_preferences')
          .select('consumption_alert_percentage')
          .eq('user_id', user.id)
          .single();

      final alertPercentage = preferencesResponse['consumption_alert_percentage'] as int;
      final increasePercentage = ((currentConsumption - averageConsumption) / averageConsumption) * 100;

      if (increasePercentage >= alertPercentage) {
        // Check if similar alert was already created today
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        
        final existingAlerts = await _client
            .from('alerts')
            .select()
            .eq('user_id', user.id)
            .eq('alert_type', 'consumption_spike')
            .gte('created_at', todayStart.toIso8601String())
            .limit(1);

        if (existingAlerts.isEmpty) {
          await createAlert(
            alertType: AlertType.consumptionSpike,
            title: 'Pic de consommation détecté',
            message: 'Votre consommation a augmenté de ${increasePercentage.toStringAsFixed(1)}% par rapport à votre moyenne habituelle.',
            thresholdValue: increasePercentage,
            thresholdType: ThresholdType.percentage,
            triggeredAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      // Silently handle errors in background checks
    }
  }

  // Check and create bill due alerts
  static Future<void> checkBillDueAlerts() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    try {
      // Get unpaid bills due in next 7 days
      final nextWeek = DateTime.now().add(const Duration(days: 7));
      
      final upcomingBills = await _client
          .from('bills')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'unpaid')
          .lte('due_date', nextWeek.toIso8601String().split('T')[0])
          .gte('due_date', DateTime.now().toIso8601String().split('T')[0]);

      for (final billData in upcomingBills) {
        final billId = billData['id'] as String;
        final amount = (billData['amount_fcfa'] as num).toDouble();
        final dueDate = DateTime.parse(billData['due_date'] as String);
        final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

        // Check if alert already exists for this bill
        final existingAlerts = await _client
            .from('alerts')
            .select()
            .eq('user_id', user.id)
            .eq('alert_type', 'bill_due')
            .ilike('message', '%${billData['bill_number']}%')
            .limit(1);

        if (existingAlerts.isEmpty) {
          String message;
          if (daysUntilDue == 0) {
            message = 'Votre facture de ${amount.toStringAsFixed(0)} FCFA arrive à échéance aujourd\'hui.';
          } else {
            message = 'Votre facture de ${amount.toStringAsFixed(0)} FCFA arrive à échéance dans $daysUntilDue jour${daysUntilDue > 1 ? 's' : ''}.';
          }

          await createAlert(
            alertType: AlertType.billDue,
            title: 'Facture à échéance',
            message: message,
            thresholdValue: amount,
            thresholdType: ThresholdType.amountFcfa,
            triggeredAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      // Silently handle errors in background checks
    }
  }

  // Check and create custom threshold alerts
  static Future<void> checkCustomThresholdAlerts(double currentMonthSpending) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    try {
      // Get user's custom threshold
      final preferencesResponse = await _client
          .from('user_preferences')
          .select('custom_threshold_fcfa')
          .eq('user_id', user.id)
          .single();

      final threshold = preferencesResponse['custom_threshold_fcfa'] as double?;
      
      if (threshold != null && currentMonthSpending >= threshold) {
        // Check if alert was already created this month
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        
        final existingAlerts = await _client
            .from('alerts')
            .select()
            .eq('user_id', user.id)
            .eq('alert_type', 'custom_threshold')
            .gte('created_at', monthStart.toIso8601String())
            .limit(1);

        if (existingAlerts.isEmpty) {
          await createAlert(
            alertType: AlertType.customThreshold,
            title: 'Seuil personnalisé atteint',
            message: 'Vous avez atteint votre seuil personnalisé de ${threshold.toStringAsFixed(0)} FCFA ce mois-ci.',
            thresholdValue: threshold,
            thresholdType: ThresholdType.amountFcfa,
            triggeredAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      // Silently handle errors in background checks
    }
  }

  // Get alert counts
  static Future<Map<String, int>> getAlertCounts() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      return {
        'total': 0,
        'unread': 0,
        'active': 0,
      };
    }

    try {
      final allAlerts = await getAlerts();
      final unreadAlerts = allAlerts.where((a) => a.isUnread).toList();
      final activeAlerts = allAlerts.where((a) => a.isActive).toList();

      return {
        'total': allAlerts.length,
        'unread': unreadAlerts.length,
        'active': activeAlerts.length,
      };
    } catch (e) {
      return {
        'total': 0,
        'unread': 0,
        'active': 0,
      };
    }
  }

  // Real-time subscription for alerts updates
  static Stream<List<AlertModel>> subscribeToAlertsUpdates() {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _client
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => (data as List<dynamic>)
            .map((json) => AlertModel.fromJson(json))
            .toList());
  }

  // Real-time subscription for outages updates
  static Stream<List<OutageModel>> subscribeToOutagesUpdates() {
    return _client
        .from('outages')
        .stream(primaryKey: ['id'])
        .order('scheduled_start', ascending: true)
        .map((data) => (data as List<dynamic>)
            .map((json) => OutageModel.fromJson(json))
            .toList());
  }

  // Helper methods
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
}