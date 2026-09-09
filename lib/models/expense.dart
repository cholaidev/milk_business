class Expense {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
  }) : assert(title.trim().isNotEmpty, 'Expense title cannot be empty'),
       assert(amount >= 0, 'Expense amount cannot be negative');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }
}
