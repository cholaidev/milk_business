import 'package:milk_business/models/customer.dart';
import 'package:milk_business/models/milk_entry.dart';
import 'package:milk_business/repositories/customer_repository.dart';
import 'package:milk_business/repositories/milk_entry_repository.dart';
import 'package:milk_business/services/billing_service.dart';
import 'package:milk_business/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyBillScreen extends StatefulWidget {
  const MonthlyBillScreen({super.key});

  @override
  State<MonthlyBillScreen> createState() => _MonthlyBillScreenState();
}

class _MonthlyBillScreenState extends State<MonthlyBillScreen> {
  final CustomerRepository _customerRepository = CustomerRepository();
  final MilkEntryRepository _milkEntryRepository = MilkEntryRepository();

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  DateTime _selectedMonth = DateTime.now();
  List<MilkEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await _customerRepository.fetchAll();
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _selectedCustomer = null;
      _entries = [];
      _loading = false;
    });
  }

  Future<void> _loadEntries() async {
    if (_selectedCustomer == null) return;
    final entries = await _milkEntryRepository.fetchEntriesForCustomerAndMonth(
      _selectedCustomer!.id!,
      _selectedMonth.year,
      _selectedMonth.month,
    );
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  MonthlyBillingBreakdown _billingBreakdown() {
    return BillingService.calculateMonthlyBreakdown(
      _entries,
      _selectedMonth.year,
      _selectedMonth.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _billingBreakdown();

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Bill')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Customer>(
                          value: _selectedCustomer,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Customer',
                          ),
                          items: _customers.map((customer) {
                            return DropdownMenuItem(
                              value: customer,
                              child: Text(customer.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCustomer = value);
                            _loadEntries();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(
                          () => _selectedMonth = DateTime(
                            picked.year,
                            picked.month,
                            1,
                          ),
                        );
                        _loadEntries();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Month'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
                          const Icon(Icons.calendar_month),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer: ${_selectedCustomer?.name ?? '-'}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 20),
                          _SectionTitle(title: 'FIRST HALF — 1 to 15'),
                          _buildTable(
                            _entries
                                .where((entry) => entry.date.day <= 15)
                                .toList(),
                          ),
                          _SummaryRow(
                            label: 'Total',
                            litres: breakdown.firstHalfTotalLitres,
                            amount: breakdown.firstHalfTotalAmount,
                          ),
                          const SizedBox(height: 20),
                          _SectionTitle(
                            title:
                                'SECOND HALF — 16 to ${DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day}',
                          ),
                          _buildTable(
                            _entries
                                .where((entry) => entry.date.day > 15)
                                .toList(),
                          ),
                          _SummaryRow(
                            label: 'Total',
                            litres: breakdown.secondHalfTotalLitres,
                            amount: breakdown.secondHalfTotalAmount,
                          ),
                          const Divider(height: 28),
                          _SummaryRow(
                            label: 'MONTHLY TOTAL',
                            litres: breakdown.totalLitres,
                            amount: breakdown.totalAmount,
                            emphatic: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTable(List<MilkEntry> entries) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No records for this period.'),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Morning',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Evening',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ...entries.map((entry) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(DateFormat('dd MMM').format(entry.date)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${entry.morningLitres.toStringAsFixed(1)}L'),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${entry.eveningLitres.toStringAsFixed(1)}L'),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${entry.totalLitres.toStringAsFixed(1)}L'),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double litres;
  final double amount;
  final bool emphatic;

  const _SummaryRow({
    super.key,
    required this.label,
    required this.litres,
    required this.amount,
    this.emphatic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: emphatic ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          Text(
            '${litres.toStringAsFixed(1)} L  •  ${AppFormatters.formatCurrency(amount)}',
            style: TextStyle(
              fontWeight: emphatic ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
