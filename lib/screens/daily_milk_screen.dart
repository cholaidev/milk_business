import 'package:milk_business/models/customer.dart';
import 'package:milk_business/models/milk_entry.dart';
import 'package:milk_business/repositories/customer_repository.dart';
import 'package:milk_business/repositories/milk_entry_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyMilkScreen extends StatefulWidget {
  final VoidCallback? onCustomerChanged;

  const DailyMilkScreen({super.key, this.onCustomerChanged});

  @override
  State<DailyMilkScreen> createState() => _DailyMilkScreenState();
}

class _DailyMilkScreenState extends State<DailyMilkScreen> {
  final CustomerRepository _customerRepository = CustomerRepository();
  final MilkEntryRepository _milkEntryRepository = MilkEntryRepository();

  List<Customer> _customers = [];
  List<MilkEntry> _milkEntries = [];
  Customer? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _morningController = TextEditingController();
  final TextEditingController _eveningController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
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
      _customers = customers.where((customer) => customer.isActive).toList();
      _selectedCustomer = null;
      _rateController.clear();
      _loading = false;
    });
  }

  Future<void> _loadMilkEntries() async {
    final entries = await _milkEntryRepository.fetchAll();
    final customerMap = {
      for (final customer in _customers) customer.id!: customer,
    };

    final filtered = entries.where((entry) {
      final sameDate =
          entry.date.year == _selectedDate.year &&
          entry.date.month == _selectedDate.month &&
          entry.date.day == _selectedDate.day;
      final sameCustomer =
          _selectedCustomer == null ||
          entry.customerId == _selectedCustomer!.id;
      return sameDate && sameCustomer;
    }).toList();

    filtered.sort((a, b) => a.customerId.compareTo(b.customerId));

    if (!mounted) return;
    setState(() {
      _milkEntries = filtered
          .map(
            (entry) => MilkEntry(
              id: entry.id,
              customerId: entry.customerId,
              date: entry.date,
              morningLitres: entry.morningLitres,
              eveningLitres: entry.eveningLitres,
              rate: entry.rate,
            ),
          )
          .toList();
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
      await _loadMilkEntries();
    }
  }

  Future<void> _saveEntry([MilkEntry? editingEntry]) async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a customer first.')));
      return;
    }

    final morning = double.tryParse(_morningController.text) ?? 0;
    final evening = double.tryParse(_eveningController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;

    if (morning < 0 || evening < 0 || rate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Values cannot be negative.')),
      );
      return;
    }

    final entry = MilkEntry(
      id: editingEntry?.id,
      customerId: _selectedCustomer!.id!,
      date: _selectedDate,
      morningLitres: morning,
      eveningLitres: evening,
      rate: rate,
    );

    if (editingEntry == null) {
      await _milkEntryRepository.insert(entry);
    } else {
      await _milkEntryRepository.update(entry);
    }

    if (!mounted) return;

    _morningController.clear();
    _eveningController.clear();
    _rateController.text = _selectedCustomer!.defaultRate.toStringAsFixed(0);
    await _loadMilkEntries();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          editingEntry == null ? 'Milk entry saved.' : 'Milk entry updated.',
        ),
      ),
    );
  }

  Future<void> _showEditEntryDialog(MilkEntry entry) async {
    final morningController = TextEditingController(
      text: entry.morningLitres.toStringAsFixed(1),
    );
    final eveningController = TextEditingController(
      text: entry.eveningLitres.toStringAsFixed(1),
    );
    final rateController = TextEditingController(
      text: entry.rate.toStringAsFixed(0),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit milk entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: morningController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Morning milk (L)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: eveningController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Evening milk (L)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Rate per litre (₹)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              _morningController.text = morningController.text;
              _eveningController.text = eveningController.text;
              _rateController.text = rateController.text;
              await _saveEntry(entry);
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadMilkEntries();
    }
  }

  Future<void> _deleteEntry(MilkEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete milk entry?'),
        content: Text(
          'Delete ${entry.customerId} entry for ${DateFormat('dd MMM').format(entry.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _milkEntryRepository.delete(entry.id!);
      await _loadMilkEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Today’s Milk')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Customer'),
                      items: _customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer,
                          child: Text(customer.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCustomer = value;
                            _rateController.text = value.defaultRate
                                .toStringAsFixed(0);
                          });
                          _loadMilkEntries();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _morningController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Morning milk (L)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _eveningController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Evening milk (L)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Rate per litre (₹)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saveEntry,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Entry'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Today milk list',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_milkEntries.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No milk entries for this date yet.'),
                        ),
                      )
                    else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _milkEntries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = _milkEntries[index];
                          final customerName =
                              _customers
                                  .where(
                                    (customer) =>
                                        customer.id == entry.customerId,
                                  )
                                  .firstOrNull
                                  ?.name ??
                              'Customer';

                          final totalMilk = entry.totalLitres;

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.local_drink),
                              ),
                              title: Text(customerName),
                              subtitle: Text(
                                'M: ${entry.morningLitres} L • E: ${entry.eveningLitres} L',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () =>
                                        _showEditEntryDialog(entry),
                                    tooltip: 'Edit milk entry',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => _deleteEntry(entry),
                                    tooltip: 'Delete milk entry',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total milk',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_milkEntries.fold<double>(0, (sum, item) => sum + item.totalLitres).toStringAsFixed(1)} L',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
