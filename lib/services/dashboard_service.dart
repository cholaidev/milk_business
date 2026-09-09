import 'package:milk_business/models/customer.dart';
import 'package:milk_business/models/expense.dart';
import 'package:milk_business/models/milk_entry.dart';

enum DashboardFilter { today, month, first15, last15 }

class DashboardSummary {
  final int totalCustomers;
  final int customersWhoBoughtMilk;
  final double soldLitres;
  final double boughtLitres;
  final double salesAmount;
  final double purchaseAmount;
  final double expenses;
  final double estimatedProfit;

  const DashboardSummary({
    required this.totalCustomers,
    required this.customersWhoBoughtMilk,
    required this.soldLitres,
    required this.boughtLitres,
    required this.salesAmount,
    required this.purchaseAmount,
    required this.expenses,
    required this.estimatedProfit,
  });
}

class DashboardService {
  static DashboardSummary buildSummary({
    required List<Customer> customers,
    required List<MilkEntry> entries,
    required List<Expense> expenses,
    required DateTime referenceDate,
    required DashboardFilter filter,
  }) {
    final filteredEntries = entries.where((entry) {
      switch (filter) {
        case DashboardFilter.today:
          return entry.date.year == referenceDate.year &&
              entry.date.month == referenceDate.month &&
              entry.date.day == referenceDate.day;
        case DashboardFilter.month:
          return entry.date.year == referenceDate.year &&
              entry.date.month == referenceDate.month;
        case DashboardFilter.first15:
          return entry.date.year == referenceDate.year &&
              entry.date.month == referenceDate.month &&
              entry.date.day <= 15;
        case DashboardFilter.last15:
          return entry.date.year == referenceDate.year &&
              entry.date.month == referenceDate.month &&
              entry.date.day > 15;
      }
    }).toList();

    final filteredExpenses = expenses.where((expense) {
      switch (filter) {
        case DashboardFilter.today:
          return expense.date.year == referenceDate.year &&
              expense.date.month == referenceDate.month &&
              expense.date.day == referenceDate.day;
        case DashboardFilter.month:
          return expense.date.year == referenceDate.year &&
              expense.date.month == referenceDate.month;
        case DashboardFilter.first15:
          return expense.date.year == referenceDate.year &&
              expense.date.month == referenceDate.month &&
              expense.date.day <= 15;
        case DashboardFilter.last15:
          return expense.date.year == referenceDate.year &&
              expense.date.month == referenceDate.month &&
              expense.date.day > 15;
      }
    }).toList();

    final totalCustomers = customers.length;
    final customerIds = filteredEntries
        .map((entry) => entry.customerId)
        .toSet();
    final customersWhoBoughtMilk = customerIds.length;

    final soldLitres = filteredEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalLitres,
    );
    final salesAmount = filteredEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    final boughtLitres = soldLitres * 0.75;
    final purchaseAmount = salesAmount * 0.7;
    final expensesTotal = filteredExpenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final estimatedProfit = salesAmount - purchaseAmount - expensesTotal;

    return DashboardSummary(
      totalCustomers: totalCustomers,
      customersWhoBoughtMilk: customersWhoBoughtMilk,
      soldLitres: soldLitres,
      boughtLitres: boughtLitres,
      salesAmount: salesAmount,
      purchaseAmount: purchaseAmount,
      expenses: expensesTotal,
      estimatedProfit: estimatedProfit,
    );
  }
}
