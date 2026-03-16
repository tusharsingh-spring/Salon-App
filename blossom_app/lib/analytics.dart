import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/api_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedPeriod = 'Week';

  List<dynamic> _popularServices = [];
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.fetchDashboardData();

    try {
      final apiService = ApiService();
      _popularServices = await apiService.getServicePopularity(30);
    } catch (e) {
       print('Error loading service popularity: $e');
    }


    if (mounted) {
      setState(() {
        _dashboardData = provider.dashboardData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Services'),
            Tab(text: 'Monthly'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildServicesTab(),
          _buildMonthlyTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final todayEarnings = _dashboardData['today_earnings'] ?? {'total_earnings': 0, 'appointment_count': 0};
    final monthlySummary = _dashboardData['monthly_summary'] ?? {};
    final totalCustomers = _dashboardData['total_customers'] ?? 0;
    final totalServices = _dashboardData['total_services'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPeriodButton('Week'),
              _buildPeriodButton('Month'),
              _buildPeriodButton('Year'),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildSummaryCard(
                'Today\'s Earnings',
                '₹${todayEarnings['total_earnings']}',
                Icons.today,
                Colors.green,
                '${todayEarnings['appointment_count']} appointments',
              ),
              _buildSummaryCard(
                'Total Customers',
                totalCustomers.toString(),
                Icons.people,
                Colors.blue,
                'Registered users',
              ),
              _buildSummaryCard(
                'Total Services',
                totalServices.toString(),
                Icons.spa,
                Colors.purple,
                'Available services',
              ),
              _buildSummaryCard(
                'This Month',
                '₹${monthlySummary['total_earnings'] ?? 0}',
                Icons.money,
                Colors.orange,
                '${monthlySummary['total_appointments'] ?? 0} appointments',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Simple Bar Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 6000,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() >= 0 && value.toInt() < days.length) {
                                  return Text(days[value.toInt()]);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: [2500, 3200, 2800, 4100, 3900, 5200, 4800][index].toDouble(),
                                color: Colors.pink,
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildActivityItem(
                    'New appointment booked',
                    'Sarah Johnson - Haircut',
                    '10 minutes ago',
                    Icons.event_available,
                  ),
                  _buildActivityItem(
                    'Payment received',
                    '₹500 from Emily Davis',
                    '1 hour ago',
                    Icons.payment,
                  ),
                  _buildActivityItem(
                    'New customer registered',
                    'Michael Brown',
                    '3 hours ago',
                    Icons.person_add,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    if (_popularServices.isEmpty) {
      return const Center(
        child: Text('No service data available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _popularServices.length,
      itemBuilder: (context, index) {
        final service = _popularServices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.spa, color: Colors.pink),
            ),
            title: Text(service['service_name'] ?? 'Service'),
            subtitle: Text('${service['appointment_count'] ?? 0} appointments'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${service['total_revenue'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${service['percentage'] ?? 0}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyTab() {
    final monthlySummary = _dashboardData['monthly_summary'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {},
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMonthlyStat(
                          'Total Revenue',
                          '₹${monthlySummary['total_earnings'] ?? 0}',
                          Icons.currency_rupee,
                          Colors.green
                      ),
                      _buildMonthlyStat(
                          'Appointments',
                          '${monthlySummary['total_appointments'] ?? 0}',
                          Icons.calendar_today,
                          Colors.blue
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMonthlyStat(
                          'Services',
                          '${monthlySummary['total_services'] ?? 0}',
                          Icons.spa,
                          Colors.purple
                      ),
                      _buildMonthlyStat(
                          'Avg. Bill',
                          '₹${monthlySummary['average_bill'] ?? 0}',
                          Icons.trending_up,
                          Colors.orange
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    return FilterChip(
      label: Text(period),
      selected: selectedPeriod == period,
      onSelected: (selected) {
        setState(() {
          selectedPeriod = period;
        });
      },
      selectedColor: Colors.pink[100],
      checkmarkColor: Colors.pink,
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Icon(icon, color: Colors.pink, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildMonthlyStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}