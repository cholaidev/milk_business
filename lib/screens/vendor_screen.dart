import 'package:milk_business/models/expense.dart';
import 'package:milk_business/repositories/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ExpenseFilter { today, month, all }

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final ExpenseRepository _repository = ExpenseRepository();
  List<Expense> _expenses = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  ExpenseFilter _selectedFilter = ExpenseFilter.month;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await _repository.fetchAll();
    if (!mounted) return;

    final filtered = expenses.where((expense) {
      switch (_selectedFilter) {
        case ExpenseFilter.today:
          return expense.date.year == _selectedDate.year &&
              expense.date.month == _selectedDate.month &&
              expense.date.day == _selectedDate.day;
        case ExpenseFilter.month:
          return expense.date.year == _selectedDate.year &&
              expense.date.month == _selectedDate.month;
        case ExpenseFilter.all:
          return true;
      }
    }).toList();

    setState(() {
      _expenses = filtered;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadExpenses();
    }
  }

  Future<void> _saveExpense() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter expense title and valid amount.')),
      );
      return;
    }

    await _repository.insert(
      Expense(title: title, amount: amount, date: _selectedDate),
    );
    _titleController.clear();
    _amountController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: $title • ₹${amount.toStringAsFixed(0)}')),
    );
    await _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense name',
                        hintText: 'Petrol, home, purchase, etc.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                      ),
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
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saveExpense,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Expense'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Expense list',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        DropdownButton<ExpenseFilter>(
                          value: _selectedFilter,
                          items: const [
                            DropdownMenuItem(
                              value: ExpenseFilter.today,
                              child: Text('Today'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseFilter.month,
                              child: Text('This month'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseFilter.all,
                              child: Text('All'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedFilter = value);
                              _loadExpenses();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFilter == ExpenseFilter.today
                                  ? 'Today'
                                  : _selectedFilter == ExpenseFilter.month
                                  ? 'This Month'
                                  : 'All Expenses',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total expenses: ₹${totalExpenses.toStringAsFixed(0)}',
                            ),
                            if (_expenses.isNotEmpty)
                              ..._expenses
                                  .take(5)
                                  .map(
                                    (expense) => Text(
                                      '${DateFormat('dd MMM').format(expense.date)} • ${expense.title}: ₹${expense.amount.toStringAsFixed(0)}',
                                    ),
                                  )
                            else
                              const Text('No expenses in this filter.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
