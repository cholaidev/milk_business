class Customer {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final double defaultRate;
  final bool isActive;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.defaultRate,
    required this.isActive,
  }) : assert(name.trim().isNotEmpty, 'Customer name cannot be empty'),
       assert(phone.trim().isNotEmpty, 'Phone number cannot be empty'),
       assert(defaultRate >= 0, 'Default rate cannot be negative');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'default_rate': defaultRate,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      defaultRate: (map['default_rate'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
    );
  }
}
