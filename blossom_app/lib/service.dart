import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> with SingleTickerProviderStateMixin {
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
      if (category != null && category.toString().isNotEmpty) {
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
    final name = service['name']?.toString() ?? 'Unnamed Service';
    final category = service['category']?.toString() ?? 'General';
    final description = service['description']?.toString() ?? '';
    final price = service['price']?.toString() ?? '0';
    final duration = service['duration']?.toString() ?? '30';

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
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.currency_rupee, size: 16, color: Colors.green),
                          Text(
                            price,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, size: 16, color: Colors.blue),
                          Text(
                            '$duration min',
                            style: const TextStyle(fontSize: 14, color: Colors.blue),
                          ),
                        ],
                      ),
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
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterServices,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
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
              // Add service functionality
            },
            backgroundColor: Colors.pink,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}