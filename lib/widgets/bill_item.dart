import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voltwatch/models/bill_model.dart';

class BillItem extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;
  final VoidCallback? onPayPressed;

  const BillItem({
    super.key,
    required this.bill,
    this.onTap,
    this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getBillStatusColor(bill.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: bill.isOverdue ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: bill.isOverdue
                ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Bill icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Bill info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Facture ${bill.billNumber}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Émise le ${DateFormat('dd/MM/yyyy').format(bill.issueDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bill.statusLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Amount and consumption
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Montant',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${NumberFormat('#,###', 'fr_FR').format(bill.totalAmount)} FCFA',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consommation',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${bill.consumptionKwh.toStringAsFixed(1)} kWh',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Due date row
                Row(
                  children: [
                    Icon(
                      bill.isOverdue ? Icons.warning : Icons.schedule,
                      size: 16,
                      color: bill.isOverdue 
                          ? Colors.red 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bill.isOverdue 
                          ? 'En retard depuis le ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}'
                          : 'Échéance: ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: bill.isOverdue 
                            ? Colors.red 
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: bill.isOverdue ? FontWeight.w500 : null,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Days until/past due
                    if (!bill.isPaid) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bill.isOverdue 
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bill.isOverdue 
                              ? '${bill.daysUntilDue.abs()} jour${bill.daysUntilDue.abs() > 1 ? 's' : ''} de retard'
                              : '${bill.daysUntilDue} jour${bill.daysUntilDue > 1 ? 's' : ''} restant${bill.daysUntilDue > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: bill.isOverdue ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Late fees
                if (bill.lateFeeFcfa > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pénalités de retard: ${NumberFormat('#,###', 'fr_FR').format(bill.lateFeeFcfa)} FCFA',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action button
                if (onPayPressed != null && (bill.isUnpaid || bill.isOverdue)) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onPayPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: bill.isOverdue ? Colors.red : null,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        bill.isOverdue ? 'Payer maintenant' : 'Payer',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
}

class BillSummaryCard extends StatelessWidget {
  final List<BillModel> bills;
  final VoidCallback? onTap;

  const BillSummaryCard({
    super.key,
    required this.bills,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final totalAmount = bills.fold<double>(0, (sum, bill) => sum + bill.totalAmount);
    final unpaidBills = bills.where((bill) => !bill.isPaid).toList();
    final overdueBills = bills.where((bill) => bill.isOverdue).toList();
    
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mes Factures',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (overdueBills.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        overdueBills.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Total amount
              Row(
                children: [
                  Text(
                    'Montant total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${NumberFormat('#,###', 'fr_FR').format(totalAmount)} FCFA',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _buildBillStat(
                      context,
                      'Total',
                      bills.length.toString(),
                      Icons.receipt_long_outlined,
                      theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildBillStat(
                      context,
                      'Impayées',
                      unpaidBills.length.toString(),
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildBillStat(
                      context,
                      'En retard',
                      overdueBills.length.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}