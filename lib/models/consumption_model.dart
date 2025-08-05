class ConsumptionReading {
  final String id;
  final String userId;
  final DateTime readingDate;
  final double kwhConsumed;
  final double costFcfa;
  final double? meterReading;
  final double? localAverageKwh;
  final DateTime createdAt;

  ConsumptionReading({
    required this.id,
    required this.userId,
    required this.readingDate,
    required this.kwhConsumed,
    required this.costFcfa,
    this.meterReading,
    this.localAverageKwh,
    required this.createdAt,
  });

  factory ConsumptionReading.fromJson(Map<String, dynamic> json) {
    return ConsumptionReading(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      readingDate: DateTime.parse(json['reading_date'] as String),
      kwhConsumed: (json['kwh_consumed'] as num).toDouble(),
      costFcfa: (json['cost_fcfa'] as num).toDouble(),
      meterReading: json['meter_reading']?.toDouble(),
      localAverageKwh: json['local_average_kwh']?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'reading_date': readingDate.toIso8601String().split('T')[0],
      'kwh_consumed': kwhConsumed,
      'cost_fcfa': costFcfa,
      'meter_reading': meterReading,
      'local_average_kwh': localAverageKwh,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get costPerKwh => kwhConsumed > 0 ? costFcfa / kwhConsumed : 0;

  double get comparisonWithAverage {
    if (localAverageKwh == null || localAverageKwh! == 0) return 0;
    return ((kwhConsumed - localAverageKwh!) / localAverageKwh!) * 100;
  }

  bool get isAboveAverage => comparisonWithAverage > 0;
}

enum ConsumptionPeriod { daily, weekly, monthly }

class ConsumptionSummary {
  final ConsumptionPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double totalKwh;
  final double totalCostFcfa;
  final double averageKwhPerDay;
  final double averageCostPerDay;
  final double comparedToLastPeriod;
  final List<ConsumptionReading> readings;

  ConsumptionSummary({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalKwh,
    required this.totalCostFcfa,
    required this.averageKwhPerDay,
    required this.averageCostPerDay,
    required this.comparedToLastPeriod,
    required this.readings,
  });

  factory ConsumptionSummary.fromReadings(
    List<ConsumptionReading> readings,
    ConsumptionPeriod period,
    DateTime startDate,
    DateTime endDate, {
    double comparedToLastPeriod = 0,
  }) {
    final totalKwh = readings.fold<double>(0, (sum, reading) => sum + reading.kwhConsumed);
    final totalCostFcfa = readings.fold<double>(0, (sum, reading) => sum + reading.costFcfa);
    final days = endDate.difference(startDate).inDays + 1;

    return ConsumptionSummary(
      period: period,
      startDate: startDate,
      endDate: endDate,
      totalKwh: totalKwh,
      totalCostFcfa: totalCostFcfa,
      averageKwhPerDay: totalKwh / days,
      averageCostPerDay: totalCostFcfa / days,
      comparedToLastPeriod: comparedToLastPeriod,
      readings: readings,
    );
  }

  String get periodLabel {
    switch (period) {
      case ConsumptionPeriod.daily:
        return 'Aujourd\'hui';
      case ConsumptionPeriod.weekly:
        return 'Cette semaine';
      case ConsumptionPeriod.monthly:
        return 'Ce mois';
    }
  }

  bool get isIncreasing => comparedToLastPeriod > 0;
  bool get isDecreasing => comparedToLastPeriod < 0;
  bool get isStable => comparedToLastPeriod == 0;
}

class ConsumptionChartData {
  final DateTime date;
  final double kwh;
  final double cost;
  final double? localAverage;

  ConsumptionChartData({
    required this.date,
    required this.kwh,
    required this.cost,
    this.localAverage,
  });

  factory ConsumptionChartData.fromReading(ConsumptionReading reading) {
    return ConsumptionChartData(
      date: reading.readingDate,
      kwh: reading.kwhConsumed,
      cost: reading.costFcfa,
      localAverage: reading.localAverageKwh,
    );
  }
}