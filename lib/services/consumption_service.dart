import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voltwatch/supabase/supabase_config.dart';
import 'package:voltwatch/models/consumption_model.dart';

class ConsumptionService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Get consumption readings
  static Future<List<ConsumptionReading>> getConsumptionReadings({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final queryBuilder = _client
          .from('consumption_readings')
          .select()
          .eq('user_id', user.id)
          .order('reading_date', ascending: false);

      if (limit != null) {
        queryBuilder.limit(limit);
      }

      final response = await queryBuilder;
      
      var filteredData = response as List<dynamic>;
      
      // Apply date filters in code if needed
      if (startDate != null || endDate != null) {
        filteredData = filteredData.where((item) {
          final readingDate = DateTime.parse(item['reading_date'] as String);
          if (startDate != null && readingDate.isBefore(startDate)) return false;
          if (endDate != null && readingDate.isAfter(endDate)) return false;
          return true;
        }).toList();
      }
      
      return filteredData
          .map((json) => ConsumptionReading.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des données de consommation: $e');
    }
  }

  // Get today's consumption
  static Future<ConsumptionReading?> getTodayConsumption() async {
    final today = DateTime.now();
    final readings = await getConsumptionReadings(
      startDate: today,
      endDate: today,
      limit: 1,
    );
    
    return readings.isNotEmpty ? readings.first : null;
  }

  // Get consumption summary for different periods
  static Future<ConsumptionSummary> getConsumptionSummary(ConsumptionPeriod period) async {
    DateTime startDate;
    DateTime endDate = DateTime.now();

    switch (period) {
      case ConsumptionPeriod.daily:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        break;
      case ConsumptionPeriod.weekly:
        startDate = endDate.subtract(Duration(days: endDate.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case ConsumptionPeriod.monthly:
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
    }

    final readings = await getConsumptionReadings(
      startDate: startDate,
      endDate: endDate,
    );

    // Calculate comparison with previous period
    DateTime previousStartDate;
    DateTime previousEndDate;
    final periodDuration = endDate.difference(startDate);

    switch (period) {
      case ConsumptionPeriod.daily:
        previousStartDate = startDate.subtract(const Duration(days: 1));
        previousEndDate = startDate.subtract(const Duration(seconds: 1));
        break;
      case ConsumptionPeriod.weekly:
        previousStartDate = startDate.subtract(const Duration(days: 7));
        previousEndDate = startDate.subtract(const Duration(seconds: 1));
        break;
      case ConsumptionPeriod.monthly:
        previousStartDate = DateTime(startDate.year, startDate.month - 1, 1);
        previousEndDate = DateTime(startDate.year, startDate.month, 0);
        break;
    }

    final previousReadings = await getConsumptionReadings(
      startDate: previousStartDate,
      endDate: previousEndDate,
    );

    final currentTotal = readings.fold<double>(0, (sum, reading) => sum + reading.costFcfa);
    final previousTotal = previousReadings.fold<double>(0, (sum, reading) => sum + reading.costFcfa);

    double comparedToLastPeriod = 0;
    if (previousTotal > 0) {
      comparedToLastPeriod = ((currentTotal - previousTotal) / previousTotal) * 100;
    }

    return ConsumptionSummary.fromReadings(
      readings,
      period,
      startDate,
      endDate,
      comparedToLastPeriod: comparedToLastPeriod,
    );
  }

  // Add consumption reading
  static Future<ConsumptionReading> addConsumptionReading({
    required DateTime readingDate,
    required double kwhConsumed,
    required double costFcfa,
    double? meterReading,
    double? localAverageKwh,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final response = await _client
          .from('consumption_readings')
          .insert({
            'user_id': user.id,
            'reading_date': readingDate.toIso8601String().split('T')[0],
            'kwh_consumed': kwhConsumed,
            'cost_fcfa': costFcfa,
            'meter_reading': meterReading,
            'local_average_kwh': localAverageKwh,
          })
          .select()
          .single();

      return ConsumptionReading.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la lecture: $e');
    }
  }

  // Update consumption reading
  static Future<ConsumptionReading> updateConsumptionReading({
    required String id,
    double? kwhConsumed,
    double? costFcfa,
    double? meterReading,
    double? localAverageKwh,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final updateData = <String, dynamic>{};
      if (kwhConsumed != null) updateData['kwh_consumed'] = kwhConsumed;
      if (costFcfa != null) updateData['cost_fcfa'] = costFcfa;
      if (meterReading != null) updateData['meter_reading'] = meterReading;
      if (localAverageKwh != null) updateData['local_average_kwh'] = localAverageKwh;

      final response = await _client
          .from('consumption_readings')
          .update(updateData)
          .eq('id', id)
          .eq('user_id', user.id)
          .select()
          .single();

      return ConsumptionReading.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la lecture: $e');
    }
  }

  // Delete consumption reading
  static Future<void> deleteConsumptionReading(String id) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      await _client
          .from('consumption_readings')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la lecture: $e');
    }
  }

  // Get consumption chart data
  static Future<List<ConsumptionChartData>> getConsumptionChartData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final readings = await getConsumptionReadings(
      startDate: startDate,
      endDate: endDate,
    );

    return readings
        .map((reading) => ConsumptionChartData.fromReading(reading))
        .toList()
        .reversed
        .toList(); // Reverse to get chronological order
  }

  // Calculate consumption statistics
  static Future<Map<String, dynamic>> getConsumptionStatistics() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      // Get last 30 days data
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      
      final readings = await getConsumptionReadings(
        startDate: startDate,
        endDate: endDate,
      );

      if (readings.isEmpty) {
        return {
          'total_kwh': 0.0,
          'total_cost': 0.0,
          'average_daily_kwh': 0.0,
          'average_daily_cost': 0.0,
          'peak_day_kwh': 0.0,
          'peak_day_cost': 0.0,
          'most_efficient_day': null,
          'comparison_with_local_average': 0.0,
        };
      }

      final totalKwh = readings.fold<double>(0, (sum, r) => sum + r.kwhConsumed);
      final totalCost = readings.fold<double>(0, (sum, r) => sum + r.costFcfa);
      final averageDailyKwh = totalKwh / readings.length;
      final averageDailyCost = totalCost / readings.length;

      final peakKwhReading = readings.reduce((a, b) => 
          a.kwhConsumed > b.kwhConsumed ? a : b);
      final peakCostReading = readings.reduce((a, b) => 
          a.costFcfa > b.costFcfa ? a : b);

      // Find most efficient day (lowest cost per kWh)
      final efficiencyReadings = readings.where((r) => r.kwhConsumed > 0).toList();
      ConsumptionReading? mostEfficientReading;
      if (efficiencyReadings.isNotEmpty) {
        mostEfficientReading = efficiencyReadings.reduce((a, b) => 
            a.costPerKwh < b.costPerKwh ? a : b);
      }

      // Calculate comparison with local average
      final readingsWithAverage = readings.where((r) => r.localAverageKwh != null).toList();
      double comparisonWithLocalAverage = 0;
      if (readingsWithAverage.isNotEmpty) {
        final userAverage = readingsWithAverage.fold<double>(0, (sum, r) => sum + r.kwhConsumed) / readingsWithAverage.length;
        final localAverage = readingsWithAverage.fold<double>(0, (sum, r) => sum + r.localAverageKwh!) / readingsWithAverage.length;
        if (localAverage > 0) {
          comparisonWithLocalAverage = ((userAverage - localAverage) / localAverage) * 100;
        }
      }

      return {
        'total_kwh': totalKwh,
        'total_cost': totalCost,
        'average_daily_kwh': averageDailyKwh,
        'average_daily_cost': averageDailyCost,
        'peak_day_kwh': peakKwhReading.kwhConsumed,
        'peak_day_cost': peakCostReading.costFcfa,
        'most_efficient_day': mostEfficientReading?.readingDate,
        'comparison_with_local_average': comparisonWithLocalAverage,
        'days_count': readings.length,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // Real-time subscription for consumption updates
  static Stream<List<ConsumptionReading>> subscribeToConsumptionUpdates() {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _client
        .from('consumption_readings')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('reading_date', ascending: false)
        .map((data) => (data as List<dynamic>)
            .map((json) => ConsumptionReading.fromJson(json))
            .toList());
  }
}