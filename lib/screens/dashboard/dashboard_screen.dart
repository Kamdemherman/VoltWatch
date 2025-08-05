import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:voltwatch/services/auth_service.dart';
import 'package:voltwatch/services/consumption_service.dart';
import 'package:voltwatch/services/bills_service.dart';
import 'package:voltwatch/services/alerts_service.dart';
import 'package:voltwatch/models/user_model.dart';
import 'package:voltwatch/models/consumption_model.dart';
import 'package:voltwatch/models/bill_model.dart';
import 'package:voltwatch/models/alert_model.dart';
import 'package:voltwatch/screens/auth/login_screen.dart';
import 'package:voltwatch/screens/profile/profile_screen.dart';
import 'package:voltwatch/screens/bills/bills_screen.dart';
import 'package:voltwatch/widgets/consumption_chart.dart';
import 'package:voltwatch/widgets/alert_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voltwatch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Définissez ici votre thème
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  ConsumptionSummary? _todayConsumption;
  ConsumptionSummary? _weeklyConsumption;
  ConsumptionSummary? _monthlyConsumption;
  List<BillModel> _unpaidBills = [];
  List<AlertModel> _recentAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Load user profile
      _currentUser = await AuthService.getCurrentUserProfile();

      // Load consumption summaries
      final futures = await Future.wait([
        ConsumptionService.getConsumptionSummary(ConsumptionPeriod.daily),
        ConsumptionService.getConsumptionSummary(ConsumptionPeriod.weekly),
        ConsumptionService.getConsumptionSummary(ConsumptionPeriod.monthly),
        BillsService.getUnpaidBills(),
        AlertsService.getUnreadAlerts(),
      ]);

      _todayConsumption = futures[0] as ConsumptionSummary;
      _weeklyConsumption = futures[1] as ConsumptionSummary;
      _monthlyConsumption = futures[2] as ConsumptionSummary;
      _unpaidBills = futures[3] as List<BillModel>;
      _recentAlerts = (futures[4] as List<AlertModel>).take(3).toList();

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

  Future<void> _signOut() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? _buildDashboardBody() : _buildOtherScreens(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Factures',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alertes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildOtherScreens() {
    switch (_currentIndex) {
      case 1:
        return const BillsScreen();
      case 2:
        return _buildAlertsView();
      case 3:
        return const ProfileScreen();
      default:
        return _buildDashboardBody();
    }
  }

  Widget _buildDashboardBody() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour ${_currentUser?.fullName ?? 'Utilisateur'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                tooltip: 'Se déconnecter',
              ),
            ],
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Consumption overview cards
                  _buildConsumptionOverview(),
                  const SizedBox(height: 24),

                  // Weekly consumption chart
                  _buildConsumptionChart(),
                  const SizedBox(height: 24),

                  // Unpaid bills section
                  if (_unpaidBills.isNotEmpty) ...[
                    _buildUnpaidBillsSection(),
                    const SizedBox(height: 24),
                  ],

                  // Recent alerts section
                  if (_recentAlerts.isNotEmpty) ...[
                    _buildRecentAlertsSection(),
                    const SizedBox(height: 24),
                  ],

                  // Quick actions
                  _buildQuickActions(),
                  const SizedBox(height: 100), // Space for bottom nav
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConsumptionOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu de la consommation',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildConsumptionCard(
                'Aujourd\'hui',
                _todayConsumption?.totalKwh ?? 0,
                _todayConsumption?.totalCostFcfa ?? 0,
                _todayConsumption?.comparedToLastPeriod ?? 0,
                Icons.today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildConsumptionCard(
                'Cette semaine',
                _weeklyConsumption?.totalKwh ?? 0,
                _weeklyConsumption?.totalCostFcfa ?? 0,
                _weeklyConsumption?.comparedToLastPeriod ?? 0,
                Icons.calendar_view_week,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildConsumptionCard(
          'Ce mois',
          _monthlyConsumption?.totalKwh ?? 0,
          _monthlyConsumption?.totalCostFcfa ?? 0,
          _monthlyConsumption?.comparedToLastPeriod ?? 0,
          Icons.calendar_month,
          Colors.orange,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildConsumptionCard(
    String period,
    double kwh,
    double cost,
    double comparison,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    final isIncrease = comparison > 0;
    final comparisonColor = isIncrease ? Colors.red : Colors.green;
    final comparisonIcon = isIncrease ? Icons.trending_up : Icons.trending_down;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    period,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${kwh.toStringAsFixed(1)} kWh',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${NumberFormat('#,###', 'fr_FR').format(cost)} FCFA',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (comparison != 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    comparisonIcon,
                    size: 16,
                    color: comparisonColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${comparison.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: comparisonColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consommation des 7 derniers jours',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ConsumptionChart(
                readings: _weeklyConsumption?.readings ?? [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpaidBillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Factures impayées (${_unpaidBills.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: _unpaidBills.take(2).map((bill) {
              return ListTile(
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
                subtitle: Text(
                  'Échéance: ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat('#,###', 'fr_FR').format(bill.amountFcfa)} FCFA',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bill.isOverdue)
                      Text(
                        'En retard',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                onTap: () => setState(() => _currentIndex = 1),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alertes récentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 2),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recentAlerts.map((alert) => AlertCard(
          alert: alert,
          onTap: () => _markAlertAsRead(alert.id),
        )),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            _buildQuickActionCard(
              'Payer une facture',
              Icons.payment,
              Colors.green,
              () => setState(() => _currentIndex = 1),
            ),
            _buildQuickActionCard(
              'Voir les alertes',
              Icons.notifications,
              Colors.orange,
              () => setState(() => _currentIndex = 2),
            ),
            _buildQuickActionCard(
              'Mon profil',
              Icons.person,
              Colors.blue,
              () => setState(() => _currentIndex = 3),
            ),
            _buildQuickActionCard(
              'Actualiser',
              Icons.refresh,
              Colors.purple,
              _loadDashboardData,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await AlertsService.markAllAlertsAsRead();
              _loadDashboardData();
            },
            icon: const Icon(Icons.done_all),
            tooltip: 'Marquer tout comme lu',
          ),
        ],
      ),
      body: FutureBuilder<List<AlertModel>>(
        future: AlertsService.getAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune alerte'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return AlertCard(
                alert: alert,
                onTap: () => _markAlertAsRead(alert.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAlertAsRead(String alertId) async {
    try {
      await AlertsService.markAlertAsRead(alertId);
      _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }
}