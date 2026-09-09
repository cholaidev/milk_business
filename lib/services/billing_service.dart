import 'package:milk_business/models/milk_entry.dart';

class MonthlyBillingBreakdown {
  final double firstHalfTotalLitres;
  final double firstHalfTotalAmount;
  final double secondHalfTotalLitres;
  final double secondHalfTotalAmount;
  final double totalLitres;
  final double totalAmount;

  const MonthlyBillingBreakdown({
    required this.firstHalfTotalLitres,
    required this.firstHalfTotalAmount,
    required this.secondHalfTotalLitres,
    required this.secondHalfTotalAmount,
    required this.totalLitres,
    required this.totalAmount,
  });
}

class BillingService {
  static DateTimeRange getBillingRangeForMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final firstHalfEnd = DateTime(year, month, 15);

    return DateTimeRange(
      start: firstDay,
      end: lastDay,
      firstHalfEnd: firstHalfEnd,
    );
  }

  static MonthlyBillingBreakdown calculateMonthlyBreakdown(
    List<MilkEntry> entries,
    int year,
    int month,
  ) {
    final monthEntries = entries.where((entry) {
      return entry.date.year == year && entry.date.month == month;
    }).toList();

    double firstHalfLitres = 0;
    double firstHalfAmount = 0;
    double secondHalfLitres = 0;
    double secondHalfAmount = 0;

    for (final entry in monthEntries) {
      final amount = entry.amount;
      if (entry.date.day <= 15) {
        firstHalfLitres += entry.totalLitres;
        firstHalfAmount += amount;
      } else {
        secondHalfLitres += entry.totalLitres;
        secondHalfAmount += amount;
      }
    }

    final totalLitres = firstHalfLitres + secondHalfLitres;
    final totalAmount = firstHalfAmount + secondHalfAmount;

    return MonthlyBillingBreakdown(
      firstHalfTotalLitres: firstHalfLitres,
      firstHalfTotalAmount: firstHalfAmount,
      secondHalfTotalLitres: secondHalfLitres,
      secondHalfTotalAmount: secondHalfAmount,
      totalLitres: totalLitres,
      totalAmount: totalAmount,
    );
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  final DateTime firstHalfEnd;

  const DateTimeRange({
    required this.start,
    required this.end,
    required this.firstHalfEnd,
  });

  int get totalDays => end.day;
}
