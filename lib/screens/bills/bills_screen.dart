import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voltwatch/services/bills_service.dart';
import 'package:voltwatch/models/bill_model.dart';
import 'package:voltwatch/widgets/bill_item.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<BillModel> _allBills = [];
  List<BillModel> _unpaidBills = [];
  List<BillModel> _paidBills = [];
  List<BillModel> _overdueBills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        BillsService.getBills(),
        BillsService.getUnpaidBills(),
        BillsService.getBills(status: BillStatus.paid),
        BillsService.getOverdueBills(),
      ]);

      setState(() {
        _allBills = results[0] as List<BillModel>;
        _unpaidBills = results[1] as List<BillModel>;
        _paidBills = results[2] as List<BillModel>;
        _overdueBills = results[3] as List<BillModel>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Factures'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'Toutes (${_allBills.length})',
              icon: const Icon(Icons.receipt_long),
            ),
            Tab(
              text: 'Impayées (${_unpaidBills.length})',
              icon: const Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'En retard (${_overdueBills.length})',
              icon: const Icon(Icons.warning),
            ),
            Tab(
              text: 'Payées (${_paidBills.length})',
              icon: const Icon(Icons.check_circle),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadBills,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBillsList(_allBills, 'Aucune facture trouvée'),
                _buildBillsList(_unpaidBills, 'Aucune facture impayée'),
                _buildBillsList(_overdueBills, 'Aucune facture en retard'),
                _buildBillsList(_paidBills, 'Aucune facture payée'),
              ],
            ),
      floatingActionButton: _unpaidBills.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showPaymentOptions(),
              icon: const Icon(Icons.payment),
              label: const Text('Payer'),
            )
          : null,
    );
  }

  Widget _buildBillsList(List<BillModel> bills, String emptyMessage) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBills,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          return BillItem(
            bill: bill,
            onTap: () => _showBillDetails(bill),
            onPayPressed: bill.isUnpaid || bill.isOverdue
                ? () => _payBill(bill)
                : null,
          );
        },
      ),
    );
  }

  void _showBillDetails(BillModel bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildBillDetailsSheet(bill),
    );
  }

  Widget _buildBillDetailsSheet(BillModel bill) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Facture ${bill.billNumber}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getBillStatusColor(bill.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bill.statusLabel,
                          style: TextStyle(
                            color: _getBillStatusColor(bill.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Bill information
                      _buildDetailRow('Montant', '${NumberFormat('#,###', 'fr_FR').format(bill.amountFcfa)} FCFA'),
                      _buildDetailRow('Date d\'émission', DateFormat('dd/MM/yyyy').format(bill.issueDate)),
                      _buildDetailRow('Date d\'échéance', DateFormat('dd/MM/yyyy').format(bill.dueDate)),
                      _buildDetailRow('Consommation', '${bill.consumptionKwh.toStringAsFixed(1)} kWh'),
                      _buildDetailRow('Coût par kWh', '${bill.costPerKwh.toStringAsFixed(0)} FCFA'),
                      
                      if (bill.serviceChargeFcfa > 0)
                        _buildDetailRow('Frais de service', '${NumberFormat('#,###', 'fr_FR').format(bill.serviceChargeFcfa)} FCFA'),
                      
                      if (bill.taxFcfa > 0)
                        _buildDetailRow('Taxes', '${NumberFormat('#,###', 'fr_FR').format(bill.taxFcfa)} FCFA'),
                      
                      if (bill.lateFeeFcfa > 0)
                        _buildDetailRow('Pénalités de retard', '${NumberFormat('#,###', 'fr_FR').format(bill.lateFeeFcfa)} FCFA'),
                      
                      const Divider(height: 32),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total à payer',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${NumberFormat('#,###', 'fr_FR').format(bill.totalAmount)} FCFA',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Payment history
                      FutureBuilder<List<PaymentModel>>(
                        future: BillsService.getBillPayments(bill.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Historique des paiements',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                ...snapshot.data!.map((payment) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      payment.isCompleted 
                                          ? Icons.check_circle 
                                          : Icons.pending,
                                      color: payment.isCompleted 
                                          ? Colors.green 
                                          : Colors.orange,
                                    ),
                                    title: Text('${NumberFormat('#,###', 'fr_FR').format(payment.amountFcfa)} FCFA'),
                                    subtitle: Text(
                                      '${payment.paymentMethodLabel} - ${DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate)}',
                                    ),
                                    trailing: Text(payment.statusLabel),
                                  ),
                                )),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              if (bill.isUnpaid || bill.isOverdue) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _payBill(bill);
                    },
                    child: Text('Payer ${NumberFormat('#,###', 'fr_FR').format(bill.totalAmount)} FCFA'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBillStatusColor(BillStatus status) {
    switch (status) {
      case BillStatus.paid:
        return Colors.green;
      case BillStatus.unpaid:
        return Colors.orange;
      case BillStatus.overdue:
        return Colors.red;
      case BillStatus.partial:
        return Colors.blue;
    }
  }

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payer une facture',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            
            // Unpaid bills list
            ..._unpaidBills.take(3).map((bill) => ListTile(
              leading: CircleAvatar(
                backgroundColor: bill.isOverdue 
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                child: Icon(
                  Icons.receipt,
                  color: bill.isOverdue ? Colors.red : Colors.orange,
                ),
              ),
              title: Text('Facture ${bill.billNumber}'),
              subtitle: Text('${NumberFormat('#,###', 'fr_FR').format(bill.totalAmount)} FCFA'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _payBill(bill);
              },
            )),
            
            if (_unpaidBills.length > 3) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _tabController.animateTo(1);
                  },
                  child: Text('Voir toutes les factures impayées (${_unpaidBills.length})'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _payBill(BillModel bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPaymentSheet(bill),
    );
  }

  Widget _buildPaymentSheet(BillModel bill) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payer la facture ${bill.billNumber}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Montant: ${NumberFormat('#,###', 'fr_FR').format(bill.totalAmount)} FCFA',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Choisissez votre méthode de paiement',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          
          const SizedBox(height: 16),
          
          // Payment methods
          ListTile(
            leading: const Icon(Icons.phone_android, color: Colors.green),
            title: const Text('Mobile Money'),
            subtitle: const Text('MTN MoMo, Orange Money'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _processPayment(bill, PaymentMethod.mobileMoney, 'MTN MoMo'),
          ),
          
          ListTile(
            leading: const Icon(Icons.credit_card, color: Colors.blue),
            title: const Text('Carte bancaire'),
            subtitle: const Text('Visa, Mastercard'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _processPayment(bill, PaymentMethod.creditCard, 'Visa'),
          ),
          
          ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.purple),
            title: const Text('Virement bancaire'),
            subtitle: const Text('Virement direct'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _processPayment(bill, PaymentMethod.bankTransfer, 'Virement'),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _processPayment(BillModel bill, PaymentMethod method, String provider) async {
    Navigator.pop(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Traitement du paiement...'),
          ],
        ),
      ),
    );

    try {
      final success = await BillsService.processPayment(
        billId: bill.id,
        amount: bill.totalAmount,
        method: method,
        paymentDetails: {'provider': provider},
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement effectué avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBills(); // Refresh bills
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec du paiement. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}