class MilkEntry {
  final int? id;
  final int customerId;
  final DateTime date;
  final double morningLitres;
  final double eveningLitres;
  final double rate;

  MilkEntry({
    this.id,
    required this.customerId,
    required this.date,
    required this.morningLitres,
    required this.eveningLitres,
    required this.rate,
  }) : assert(morningLitres != null),
       assert(eveningLitres != null),
       assert(rate != null) {
    if (morningLitres < 0) {
      throw ArgumentError.value(
        morningLitres,
        'morningLitres',
        'Morning litres cannot be negative',
      );
    }
    if (eveningLitres < 0) {
      throw ArgumentError.value(
        eveningLitres,
        'eveningLitres',
        'Evening litres cannot be negative',
      );
    }
    if (rate < 0) {
      throw ArgumentError.value(rate, 'rate', 'Rate cannot be negative');
    }
  }

  double get totalLitres => morningLitres + eveningLitres;
  double get amount => totalLitres * rate;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'date': date.toIso8601String(),
      'morning_litres': morningLitres,
      'evening_litres': eveningLitres,
      'rate': rate,
    };
  }

  factory MilkEntry.fromMap(Map<String, dynamic> map) {
    return MilkEntry(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      date: DateTime.parse(map['date'] as String),
      morningLitres: (map['morning_litres'] as num).toDouble(),
      eveningLitres: (map['evening_litres'] as num).toDouble(),
      rate: (map['rate'] as num).toDouble(),
    );
  }
}
