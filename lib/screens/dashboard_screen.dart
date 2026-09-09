import 'package:milk_business/models/customer.dart';
import 'package:milk_business/models/expense.dart';
import 'package:milk_business/models/milk_entry.dart';
import 'package:milk_business/repositories/customer_repository.dart';
import 'package:milk_business/repositories/expense_repository.dart';
import 'package:milk_business/repositories/milk_entry_repository.dart';
import 'package:milk_business/services/dashboard_service.dart';
import 'package:milk_business/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CustomerRepository _customerRepository = CustomerRepository();
  final MilkEntryRepository _milkEntryRepository = MilkEntryRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  DashboardFilter _selectedFilter = DashboardFilter.month;
  bool _loading = true;
  DashboardSummary _summary = const DashboardSummary(
    totalCustomers: 0,
    customersWhoBoughtMilk: 0,
    soldLitres: 0,
    boughtLitres: 0,
    salesAmount: 0,
    purchaseAmount: 0,
    expenses: 0,
    estimatedProfit: 0,
  );
  DashboardSummary _monthSummary = const DashboardSummary(
    totalCustomers: 0,
    customersWhoBoughtMilk: 0,
    soldLitres: 0,
    boughtLitres: 0,
    salesAmount: 0,
    purchaseAmount: 0,
    expenses: 0,
    estimatedProfit: 0,
  );
  DashboardSummary _first15Summary = const DashboardSummary(
    totalCustomers: 0,
    customersWhoBoughtMilk: 0,
    soldLitres: 0,
    boughtLitres: 0,
    salesAmount: 0,
    purchaseAmount: 0,
    expenses: 0,
    estimatedProfit: 0,
  );
  DashboardSummary _last15Summary = const DashboardSummary(
    totalCustomers: 0,
    customersWhoBoughtMilk: 0,
    soldLitres: 0,
    boughtLitres: 0,
    salesAmount: 0,
    purchaseAmount: 0,
    expenses: 0,
    estimatedProfit: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final customers = await _customerRepository.fetchAll();
    final entries = await _milkEntryRepository.fetchAll();
    final expenses = await _expenseRepository.fetchAll();
    final now = DateTime.now();

    if (!mounted) return;

    final monthSummary = DashboardService.buildSummary(
      customers: customers,
      entries: entries,
      expenses: expenses,
      referenceDate: now,
      filter: DashboardFilter.month,
    );
    final first15Summary = DashboardService.buildSummary(
      customers: customers,
      entries: entries,
      expenses: expenses,
      referenceDate: now,
      filter: DashboardFilter.first15,
    );
    final last15Summary = DashboardService.buildSummary(
      customers: customers,
      entries: entries,
      expenses: expenses,
      referenceDate: now,
      filter: DashboardFilter.last15,
    );

    setState(() {
      _summary = DashboardService.buildSummary(
        customers: customers,
        entries: entries,
        expenses: expenses,
        referenceDate: now,
        filter: _selectedFilter,
      );
      _monthSummary = monthSummary;
      _first15Summary = first15Summary;
      _last15Summary = last15Summary;
      _loading = false;
    });
  }

  Future<void> _refreshDashboard() async {
    setState(() => _loading = true);
    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final label = switch (_selectedFilter) {
      DashboardFilter.today => 'Today',
      DashboardFilter.month => 'This month',
      DashboardFilter.first15 => '1st 15 days',
      DashboardFilter.last15 => '16th to end',
    };

    final stats = [
      _StatCard(title: 'Date', value: DateFormat('dd MMM yyyy').format(today)),
      _StatCard(
        title: 'Total customers',
        value: _summary.totalCustomers.toString(),
      ),
      _StatCard(
        title: 'Customers bought milk',
        value: _summary.customersWhoBoughtMilk.toString(),
      ),
      _StatCard(
        title: '${label} sold',
        value: '${_summary.soldLitres.toStringAsFixed(1)} L',
      ),
      _StatCard(
        title: '${label} bought',
        value: '${_summary.boughtLitres.toStringAsFixed(1)} L',
      ),
      _StatCard(
        title: 'This month sold',
        value: '${_monthSummary.soldLitres.toStringAsFixed(1)} L',
      ),
      _StatCard(
        title: '1st 15 days',
        value: '${_first15Summary.soldLitres.toStringAsFixed(1)} L',
      ),
      _StatCard(
        title: '16th to end',
        value: '${_last15Summary.soldLitres.toStringAsFixed(1)} L',
      ),
      _StatCard(
        title: 'Sales amount',
        value: AppFormatters.formatCurrency(_summary.salesAmount.toInt()),
      ),
      _StatCard(
        title: 'Purchase amount',
        value: AppFormatters.formatCurrency(_summary.purchaseAmount.toInt()),
      ),
      _StatCard(
        title: 'Expenses',
        value: AppFormatters.formatCurrency(_summary.expenses.toInt()),
      ),
      _StatCard(
        title: 'Estimated profit',
        value: AppFormatters.formatCurrency(_summary.estimatedProfit.toInt()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DashboardFilter>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: DashboardFilter.today,
                            child: Text('Today'),
                          ),
                          DropdownMenuItem(
                            value: DashboardFilter.month,
                            child: Text('This month'),
                          ),
                          DropdownMenuItem(
                            value: DashboardFilter.first15,
                            child: Text('1st 15 days'),
                          ),
                          DropdownMenuItem(
                            value: DashboardFilter.last15,
                            child: Text('16th to end'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedFilter = value);
                            _refreshDashboard();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: stats
                          .map((stat) => _StatCardWidget(stat: stat))
                          .toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatCard {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});
}

class _StatCardWidget extends StatelessWidget {
  final _StatCard stat;

  const _StatCardWidget({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stat.title, style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            Text(
              stat.value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
