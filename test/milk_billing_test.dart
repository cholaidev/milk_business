import 'package:flutter_test/flutter_test.dart';
import 'package:milk_business/models/customer.dart';
import 'package:milk_business/models/expense.dart';
import 'package:milk_business/models/milk_entry.dart';
import 'package:milk_business/services/billing_service.dart';
import 'package:milk_business/services/dashboard_service.dart';

void main() {
  group('BillingService', () {
    test('calculates first and second half totals for a 30-day month', () {
      final entries = <MilkEntry>[];
      for (var day = 1; day <= 15; day++) {
        entries.add(
          MilkEntry(
            id: day,
            customerId: 1,
            date: DateTime(2026, 9, day),
            morningLitres: 1.5,
            eveningLitres: 1.0,
            rate: 60,
          ),
        );
      }
      for (var day = 16; day <= 30; day++) {
        entries.add(
          MilkEntry(
            id: day,
            customerId: 1,
            date: DateTime(2026, 9, day),
            morningLitres: 1.5,
            eveningLitres: 1.0,
            rate: 60,
          ),
        );
      }

      final result = BillingService.calculateMonthlyBreakdown(entries, 2026, 9);

      expect(result.firstHalfTotalLitres, closeTo(37.5, 0.0001));
      expect(result.firstHalfTotalAmount, 2250);
      expect(result.secondHalfTotalLitres, closeTo(37.5, 0.0001));
      expect(result.secondHalfTotalAmount, 2250);
      expect(result.totalLitres, closeTo(75.0, 0.0001));
      expect(result.totalAmount, 4500);
    });

    test(
      'uses actual month length for February and distinct billing periods',
      () {
        final entries = [
          MilkEntry(
            id: 1,
            customerId: 1,
            date: DateTime(2024, 2, 10),
            morningLitres: 1.0,
            eveningLitres: 1.0,
            rate: 70,
          ),
          MilkEntry(
            id: 2,
            customerId: 1,
            date: DateTime(2024, 2, 29),
            morningLitres: 2.0,
            eveningLitres: 1.0,
            rate: 75,
          ),
        ];

        final result = BillingService.calculateMonthlyBreakdown(
          entries,
          2024,
          2,
        );

        expect(result.firstHalfTotalLitres, closeTo(2.0, 0.0001));
        expect(result.secondHalfTotalLitres, closeTo(3.0, 0.0001));
        expect(result.totalLitres, closeTo(5.0, 0.0001));
      },
    );

    test('preserves historical rate usage for each entry', () {
      final entries = [
        MilkEntry(
          id: 1,
          customerId: 1,
          date: DateTime(2026, 9, 10),
          morningLitres: 1.5,
          eveningLitres: 1.0,
          rate: 60,
        ),
        MilkEntry(
          id: 2,
          customerId: 1,
          date: DateTime(2026, 9, 20),
          morningLitres: 1.0,
          eveningLitres: 1.0,
          rate: 65,
        ),
      ];

      final result = BillingService.calculateMonthlyBreakdown(entries, 2026, 9);

      expect(result.firstHalfTotalAmount, 150);
      expect(result.secondHalfTotalAmount, 130);
      expect(result.totalAmount, 280);
    });

    test('rejects negative rates and quantities', () {
      expect(
        () => MilkEntry(
          id: 1,
          customerId: 1,
          date: DateTime(2026, 9, 1),
          morningLitres: -1,
          eveningLitres: 1,
          rate: 60,
        ),
        throwsArgumentError,
      );

      expect(
        () => MilkEntry(
          id: 2,
          customerId: 1,
          date: DateTime(2026, 9, 1),
          morningLitres: 1,
          eveningLitres: 1,
          rate: -60,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Customer', () {
    test('creates a valid customer record', () {
      final customer = Customer(
        id: 1,
        name: 'Ram Kumar',
        phone: '9876543210',
        address: 'Main Road',
        defaultRate: 60,
        isActive: true,
      );

      expect(customer.name, 'Ram Kumar');
      expect(customer.defaultRate, 60);
    });
  });

  group('DashboardService', () {
    test('builds totals from real customer, milk, and expense data', () {
      final customers = [
        Customer(
          id: 1,
          name: 'A',
          phone: '1111111111',
          address: 'A',
          defaultRate: 50,
          isActive: true,
        ),
        Customer(
          id: 2,
          name: 'B',
          phone: '2222222222',
          address: 'B',
          defaultRate: 60,
          isActive: true,
        ),
      ];

      final entries = [
        MilkEntry(
          id: 1,
          customerId: 1,
          date: DateTime(2026, 9, 5),
          morningLitres: 2,
          eveningLitres: 1,
          rate: 50,
        ),
        MilkEntry(
          id: 2,
          customerId: 1,
          date: DateTime(2026, 9, 18),
          morningLitres: 1,
          eveningLitres: 1,
          rate: 55,
        ),
        MilkEntry(
          id: 3,
          customerId: 2,
          date: DateTime(2026, 9, 18),
          morningLitres: 2,
          eveningLitres: 0,
          rate: 60,
        ),
      ];

      final expenses = [
        Expense(
          id: 1,
          title: 'Petrol',
          amount: 200,
          date: DateTime(2026, 9, 4),
        ),
        Expense(id: 2, title: 'Home', amount: 300, date: DateTime(2026, 9, 20)),
      ];

      final summary = DashboardService.buildSummary(
        customers: customers,
        entries: entries,
        expenses: expenses,
        referenceDate: DateTime(2026, 9, 20),
        filter: DashboardFilter.month,
      );

      expect(summary.totalCustomers, 2);
      expect(summary.customersWhoBoughtMilk, 2);
      expect(summary.soldLitres, closeTo(7, 0.0001));
      expect(summary.salesAmount, 380);
      expect(summary.expenses, 500);
      expect(summary.estimatedProfit, -386);
    });
  });
}
