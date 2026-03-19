import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredServices = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    if (!mounted) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.fetchServices();

    if (!mounted) return;

    // Extract unique categories safely
    final Set<String> categorySet = {};

    for (var service in provider.services) {
      final category = service['category'];
      if (category != null && category.toString().isNotEmpty && category.toString() != 'null') {
        categorySet.add(category.toString());
      }
    }

    setState(() {
      _filteredServices = provider.services;
      _categories = categorySet.isEmpty ? ['General'] : categorySet.toList();

      final oldController = _tabController;
      _tabController = TabController(
        length: _categories.length + 1,
        vsync: this,
      );
      oldController.dispose();
    });
  }

  Future<void> _addService(Map<String, dynamic> serviceData) async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await provider.addService(serviceData);
      if (!mounted) return;
      Navigator.pop(context);
      await _loadServices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service added successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateService(int id, Map<String, dynamic> serviceData) async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await provider.updateService(id, serviceData);
      if (!mounted) return;
      Navigator.pop(context);
      await _loadServices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service updated successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteService(int id, String name) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await provider.deleteService(id);
      if (!mounted) return;
      Navigator.pop(context);
      await _loadServices();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name deleted successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (mins)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                Navigator.pop(context);
                _addService({
                  'name': nameController.text,
                  'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                  'base_price': double.tryParse(priceController.text) ?? 0.0,
                  'duration_minutes': int.tryParse(durationController.text) ?? 30,
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> service) {
    final nameController = TextEditingController(text: service['name']?.toString() ?? '');
    final categoryController = TextEditingController(text: service['category']?.toString() ?? '');
    final descriptionController = TextEditingController(text: service['description']?.toString() ?? '');
      final priceController = TextEditingController(text: (service['base_price']?.toString() ?? service['price']?.toString() ?? '0'));
    final durationController = TextEditingController(text: (service['duration_minutes']?.toString() ?? service['duration']?.toString() ?? '30'));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (mins)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                Navigator.pop(context);
                _updateService(service['id'], {
                  'name': nameController.text,
                  'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                  'base_price': double.tryParse(priceController.text) ?? 0.0,
                  'duration_minutes': int.tryParse(durationController.text) ?? 30,
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _filterServices(String query) {
    if (!mounted) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    setState(() {
      if (query.isEmpty) {
        _filteredServices = provider.services;
      } else {
        _filteredServices = provider.services.where((service) {
          final name = service['name']?.toString().toLowerCase() ?? '';
          final category = service['category']?.toString().toLowerCase() ?? '';

          return name.contains(query.toLowerCase()) ||
              category.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  List<dynamic> _getServicesByCategory(String category) {
    if (category == 'All') {
      return _filteredServices;
    }

    return _filteredServices.where((s) {
      final serviceCategory = s['category']?.toString() ?? '';
      return serviceCategory == category;
    }).toList();
  }

  Widget _buildServiceCard(dynamic service) {
    // Default values with safe access using ?. operator
    final name = (service['name'] == null || service['name'] == 'null') ? 'Unnamed Service' : service['name'].toString();
    var category = service['category']?.toString() ?? 'General';
    if (category == 'null' || category.isEmpty) category = 'General';
    
    final description = (service['description'] == null || service['description'] == 'null') ? '' : service['description'].toString();
    final price = (service['base_price'] == null || service['base_price'] == 'null') ? 
                  ((service['price'] == null || service['price'] == 'null') ? '0' : service['price'].toString()) : service['base_price'].toString();
    final duration = (service['duration_minutes'] == null || service['duration_minutes'] == 'null') ? 
                     ((service['duration'] == null || service['duration'] == 'null') ? '30' : service['duration'].toString()) : service['duration_minutes'].toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(color: Colors.pink[700], fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (description.isNotEmpty)
              Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('$duration mins', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                      onPressed: () => _showEditDialog(service as Map<String, dynamic>),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteService(service['id'], name),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Services'),
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            bottom: _categories.isEmpty ? null : TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              tabs: [
                const Tab(text: 'All'),
                ..._categories.map((c) => Tab(text: c)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadServices,
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
                onChanged: _filterServices,
                decoration: InputDecoration(
                  hintText: 'Search services...',
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
                          onPressed: _loadServices,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredServices.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No services found'),
                    ),
                  )
                else
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ListView(
                          children: _getServicesByCategory('All').map((service) => _buildServiceCard(service)).toList(),
                        ),
                        ..._categories.map((c) => ListView(
                          children: _getServicesByCategory(c).map((service) => _buildServiceCard(service)).toList(),
                        )),
                      ],
                    ),
                  ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showAddDialog();
            },
            backgroundColor: Colors.pink,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}