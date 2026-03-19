import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.fetchCustomers();
    if (mounted) {
      setState(() {
        _filteredCustomers = provider.customers;
      });
    }
  }

  void _filterCustomers(String query) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = provider.customers;
      } else {
        _filteredCustomers = provider.customers.where((customer) {
          return customer['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
              customer['phone'].toString().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _addCustomer(Map<String, dynamic> customerData) async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await provider.addCustomer(customerData);
      if (!mounted) return;
      Navigator.pop(context);
      await _loadCustomers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateCustomer(int id, Map<String, dynamic> customerData) async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await provider.updateCustomer(id, customerData);
      if (!mounted) return;
      Navigator.pop(context);
      await _loadCustomers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCustomer(int id, String name) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await provider.deleteCustomer(id);
      if (!mounted) return;
      Navigator.pop(context);
      await _loadCustomers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  Navigator.pop(dialogContext);
                  _addCustomer({
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text,
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> customer) {
    final nameController = TextEditingController(text: customer['name']);
    final phoneController = TextEditingController(text: customer['phone']);
    final emailController = TextEditingController(text: customer['email'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  Navigator.pop(dialogContext);
                  _updateCustomer(customer['id'], {
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text,
                  });
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCustomers,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFE91E63)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
          if (provider.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: _loadCustomers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredCustomers.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No customers found'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = _filteredCustomers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFCE4EC),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            customer['name'][0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(customer['phone'], style: TextStyle(color: Colors.grey[600])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                              onPressed: () => _showEditDialog(customer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteCustomer(
                                customer['id'],
                                customer['name'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}