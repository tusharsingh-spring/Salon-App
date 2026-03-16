import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customer.dart';
import 'service.dart';
import 'work.dart';
import 'analytics.dart';
import 'providers/app_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.fetchDashboardData();
  }

  Widget _buildBigButton(
      BuildContext context,
      String label,
      Color color,
      Widget destination,
      ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        minimumSize: const Size(150, 150),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Text(
        label,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final todayEarnings = provider.dashboardData['today_earnings'] ??
        {'total_earnings': 0, 'appointment_count': 0};

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 60.0),
        child: Column(
          children: [
            if (!provider.isLoading && provider.dashboardData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.today, color: Colors.green),
                              const SizedBox(height: 8),
                              Text(
                                '₹${todayEarnings['total_earnings']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Today\'s Earnings'),
                              Text(
                                '${todayEarnings['appointment_count']} appointments',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.people, color: Colors.blue),
                              const SizedBox(height: 8),
                              Text(
                                '${provider.dashboardData['total_customers'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Total Customers'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.0,
                padding: const EdgeInsets.all(20),
                children: [
                  _buildBigButton(
                    context,
                    'Customers',
                    Colors.pink,
                    const CustomersPage(),
                  ),
                  _buildBigButton(
                    context,
                    'Services',
                    Colors.pink,
                    const ServicesPage(),
                  ),
                  _buildBigButton(
                    context,
                    'Work',
                    Colors.pink,
                    const AppointmentsPage(),
                  ),
                  _buildBigButton(
                    context,
                    'Analytics',
                    Colors.pink,
                    const AnalyticsPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}