import 'package:milk_business/models/customer.dart';
import 'package:milk_business/repositories/customer_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerScreen extends StatefulWidget {
  final VoidCallback? onCustomerChanged;

  const CustomerScreen({super.key, this.onCustomerChanged});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerRepository _repository = CustomerRepository();
  List<Customer> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await _repository.fetchAll();
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _loading = false;
    });
  }

  Future<void> _showCustomerDialog([Customer? customer]) async {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController(
      text: customer?.address ?? '',
    );
    final rateController = TextEditingController(
      text: customer == null ? '' : customer.defaultRate.toStringAsFixed(0),
    );
    bool active = customer?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer name',
                      ),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 2,
                    ),
                    TextField(
                      controller: rateController,
                      decoration: const InputDecoration(
                        labelText: 'Default milk rate per litre',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Active'),
                        const Spacer(),
                        Switch(
                          value: active,
                          onChanged: (value) =>
                              setStateDialog(() => active = value),
                        ),
                      ],
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
                    final rate = double.tryParse(rateController.text) ?? 0;
                    final phone = phoneController.text.trim();
                    if (nameController.text.trim().isEmpty ||
                        phone.isEmpty ||
                        phone.length != 10 ||
                        int.tryParse(phone) == null ||
                        rate <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid 10-digit mobile number and default milk rate greater than 0.',
                          ),
                        ),
                      );
                      return;
                    }

                    final customerData = Customer(
                      id: customer?.id,
                      name: nameController.text.trim(),
                      phone: phone,
                      address: addressController.text.trim(),
                      defaultRate: rate,
                      isActive: active,
                    );

                    if (customer == null) {
                      await _repository.insert(customerData);
                    } else {
                      await _repository.update(customerData);
                    }

                    widget.onCustomerChanged?.call();
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: Text(customer == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _loadCustomers();
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Delete ${customer.name}?'),
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
      await _repository.delete(customer.id!);
      widget.onCustomerChanged?.call();
      _loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
          ? const Center(child: Text('No customers added yet.'))
          : ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(customer.name),
                    subtitle: Text(
                      '${customer.phone}\n${customer.address}\nRate: ₹${customer.defaultRate.toStringAsFixed(0)}/L',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showCustomerDialog(customer);
                        } else if (value == 'delete') {
                          _deleteCustomer(customer);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: customer.isActive
                          ? Colors.green
                          : Colors.grey,
                      child: Text(customer.name[0].toUpperCase()),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
