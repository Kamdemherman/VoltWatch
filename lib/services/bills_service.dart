import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voltwatch/supabase/supabase_config.dart';
import 'package:voltwatch/models/bill_model.dart';

class BillsService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Get bills
  static Future<List<BillModel>> getBills({
    BillStatus? status,
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
          .from('bills')
          .select()
          .eq('user_id', user.id)
          .order('due_date', ascending: false);

      if (limit != null) {
        queryBuilder.limit(limit);
      }

      final response = await queryBuilder;
      var filteredData = response as List<dynamic>;
      
      // Apply filters in code
      if (status != null) {
        filteredData = filteredData.where((item) => 
            item['status'] == _statusToString(status)).toList();
      }
      
      if (startDate != null) {
        filteredData = filteredData.where((item) {
          final issueDate = DateTime.parse(item['issue_date'] as String);
          return !issueDate.isBefore(startDate);
        }).toList();
      }
      
      if (endDate != null) {
        filteredData = filteredData.where((item) {
          final issueDate = DateTime.parse(item['issue_date'] as String);
          return !issueDate.isAfter(endDate);
        }).toList();
      }
      
      return filteredData
          .map((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des factures: $e');
    }
  }

  // Get unpaid bills
  static Future<List<BillModel>> getUnpaidBills() async {
    return await getBills(status: BillStatus.unpaid);
  }

  // Get overdue bills
  static Future<List<BillModel>> getOverdueBills() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final response = await _client
          .from('bills')
          .select()
          .eq('user_id', user.id)
          .order('due_date', ascending: true);
          
      final filteredData = (response as List<dynamic>).where((item) {
        final status = item['status'] as String;
        final dueDate = DateTime.parse(item['due_date'] as String);
        return (status == 'unpaid' || status == 'partial') && 
               dueDate.isBefore(DateTime.now());
      }).toList();

      return filteredData
          .map((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des factures en retard: $e');
    }
  }

  // Get bill by ID
  static Future<BillModel?> getBillById(String billId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final response = await _client
          .from('bills')
          .select()
          .eq('id', billId)
          .eq('user_id', user.id)
          .single();

      return BillModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update bill status
  static Future<BillModel> updateBillStatus(String billId, BillStatus status) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final response = await _client
          .from('bills')
          .update({'status': _statusToString(status)})
          .eq('id', billId)
          .eq('user_id', user.id)
          .select()
          .single();

      return BillModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut de la facture: $e');
    }
  }

  // Get payments
  static Future<List<PaymentModel>> getPayments({
    String? billId,
    PaymentStatus? status,
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
          .from('payments')
          .select()
          .eq('user_id', user.id)
          .order('payment_date', ascending: false);

      if (limit != null) {
        queryBuilder.limit(limit);
      }

      final response = await queryBuilder;
      var filteredData = response as List<dynamic>;
      
      // Apply filters in code
      if (billId != null) {
        filteredData = filteredData.where((item) => 
            item['bill_id'] == billId).toList();
      }
      
      if (status != null) {
        filteredData = filteredData.where((item) => 
            item['status'] == _paymentStatusToString(status)).toList();
      }
      
      if (startDate != null) {
        filteredData = filteredData.where((item) {
          final paymentDate = DateTime.parse(item['payment_date'] as String);
          return !paymentDate.isBefore(startDate);
        }).toList();
      }
      
      if (endDate != null) {
        filteredData = filteredData.where((item) {
          final paymentDate = DateTime.parse(item['payment_date'] as String);
          return !paymentDate.isAfter(endDate);
        }).toList();
      }
      
      return filteredData
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements: $e');
    }
  }

  // Get payments for a specific bill
  static Future<List<PaymentModel>> getBillPayments(String billId) async {
    return await getPayments(billId: billId);
  }

  // Create payment record
  static Future<PaymentModel> createPayment({
    required String billId,
    required double amountFcfa,
    required PaymentMethod paymentMethod,
    String? paymentProvider,
    String? transactionId,
    PaymentStatus status = PaymentStatus.pending,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final response = await _client
          .from('payments')
          .insert({
            'user_id': user.id,
            'bill_id': billId,
            'amount_fcfa': amountFcfa,
            'payment_method': _paymentMethodToString(paymentMethod),
            'payment_provider': paymentProvider,
            'transaction_id': transactionId,
            'status': _paymentStatusToString(status),
            'payment_date': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création du paiement: $e');
    }
  }

  // Update payment status
  static Future<PaymentModel> updatePaymentStatus(
    String paymentId, 
    PaymentStatus status, {
    String? transactionId,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final updateData = {
        'status': _paymentStatusToString(status),
      };

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      final response = await _client
          .from('payments')
          .update(updateData)
          .eq('id', paymentId)
          .eq('user_id', user.id)
          .select()
          .single();

      final payment = PaymentModel.fromJson(response);

      // If payment is completed, update bill status
      if (status == PaymentStatus.completed) {
        await _updateBillAfterPayment(payment.billId, payment.amountFcfa);
      }

      return payment;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du paiement: $e');
    }
  }

  // Update bill status after successful payment
  static Future<void> _updateBillAfterPayment(String billId, double paidAmount) async {
    final bill = await getBillById(billId);
    if (bill == null) return;

    // Get total paid amount for this bill
    final payments = await getBillPayments(billId);
    final totalPaid = payments
        .where((p) => p.isCompleted)
        .fold<double>(0, (sum, p) => sum + p.amountFcfa);

    BillStatus newStatus;
    if (totalPaid >= bill.totalAmount) {
      newStatus = BillStatus.paid;
    } else if (totalPaid > 0) {
      newStatus = BillStatus.partial;
    } else {
      return; // No change needed
    }

    await updateBillStatus(billId, newStatus);
  }

  // Get payment statistics
  static Future<Map<String, dynamic>> getPaymentStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      // Default to last 12 months
      startDate ??= DateTime.now().subtract(const Duration(days: 365));
      endDate ??= DateTime.now();

      final payments = await getPayments(
        startDate: startDate,
        endDate: endDate,
        status: PaymentStatus.completed,
      );

      final bills = await getBills(
        startDate: startDate,
        endDate: endDate,
      );

      final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amountFcfa);
      final totalBilled = bills.fold<double>(0, (sum, b) => sum + b.amountFcfa);
      final averagePayment = payments.isNotEmpty ? totalPaid / payments.length : 0;

      // Group payments by method
      final paymentsByMethod = <PaymentMethod, double>{};
      for (final payment in payments) {
        paymentsByMethod[payment.paymentMethod] = 
            (paymentsByMethod[payment.paymentMethod] ?? 0) + payment.amountFcfa;
      }

      // Find most used payment method
      PaymentMethod? mostUsedMethod;
      double highestAmount = 0;
      paymentsByMethod.forEach((method, amount) {
        if (amount > highestAmount) {
          highestAmount = amount;
          mostUsedMethod = method;
        }
      });

      // Calculate on-time payment rate
      final unpaidBills = bills.where((b) => !b.isPaid).toList();
      final overdueBills = unpaidBills.where((b) => b.isOverdue).toList();
      final onTimePaymentRate = bills.isNotEmpty 
          ? ((bills.length - overdueBills.length) / bills.length) * 100
          : 100.0;

      return {
        'total_paid': totalPaid,
        'total_billed': totalBilled,
        'average_payment': averagePayment,
        'payment_count': payments.length,
        'bill_count': bills.length,
        'most_used_payment_method': mostUsedMethod?.toString(),
        'payments_by_method': paymentsByMethod.map((k, v) => 
            MapEntry(k.toString(), v)),
        'on_time_payment_rate': onTimePaymentRate,
        'unpaid_bills_count': unpaidBills.length,
        'overdue_bills_count': overdueBills.length,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques de paiement: $e');
    }
  }

  // Real-time subscription for bills updates
  static Stream<List<BillModel>> subscribeToBillsUpdates() {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _client
        .from('bills')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('due_date', ascending: false)
        .map((data) => (data as List<dynamic>)
            .map((json) => BillModel.fromJson(json))
            .toList());
  }

  // Real-time subscription for payments updates
  static Stream<List<PaymentModel>> subscribeToPaymentsUpdates() {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _client
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('payment_date', ascending: false)
        .map((data) => (data as List<dynamic>)
            .map((json) => PaymentModel.fromJson(json))
            .toList());
  }

  // Simulate payment processing (in real app, this would integrate with actual payment providers)
  static Future<bool> processPayment({
    required String billId,
    required double amount,
    required PaymentMethod method,
    required Map<String, String> paymentDetails,
  }) async {
    try {
      // Create payment record
      final payment = await createPayment(
        billId: billId,
        amountFcfa: amount,
        paymentMethod: method,
        paymentProvider: paymentDetails['provider'],
        status: PaymentStatus.pending,
      );

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate payment success/failure (90% success rate)
      final isSuccess = DateTime.now().millisecond % 10 != 0;

      if (isSuccess) {
        await updatePaymentStatus(
          payment.id, 
          PaymentStatus.completed,
          transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        );
        return true;
      } else {
        await updatePaymentStatus(payment.id, PaymentStatus.failed);
        return false;
      }
    } catch (e) {
      throw Exception('Erreur lors du traitement du paiement: $e');
    }
  }

  // Helper methods
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
}