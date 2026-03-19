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
  List<dynamic> _dailyEarnings = [];
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
    await provider.fetchAppointments();

    try {
      final apiService = ApiService();
      _popularServices = await apiService.getServicePopularity(30);
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 6));
      final dateFormat = DateFormat('yyyy-MM-dd');
      _dailyEarnings = await apiService.getDailyEarnings(
        dateFormat.format(startDate),
        dateFormat.format(endDate)
      );
    } catch (e) {
       print('Error loading analytics: $e');
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
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
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
    final provider = Provider.of<AppProvider>(context, listen: false);
    final todayEarnings = _dashboardData['today_earnings'] ?? {'total_earnings': 0, 'appointment_count': 0};
    final monthlySummary = _dashboardData['monthly_summary'] ?? {};
    final totalCustomers = _dashboardData['total_customers'] ?? 0;
    final totalServices = _dashboardData['total_services'] ?? 0;
    
    // Calculate max Y for chart
    double maxY = 1000;
    for (var data in _dailyEarnings) {
      double earnings = double.tryParse(data['total_earnings']?.toString() ?? '0') ?? 0;
      if (earnings > maxY) maxY = earnings;
    }
    maxY = maxY + (maxY * 0.2); // add 20% headroom

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
          const SizedBox(height: 24),

          // Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.95,
            children: [
              _buildSummaryCard(
                'Today\'s Earnings',
                '₹${todayEarnings['total_earnings']}',
                Icons.account_balance_wallet,
                const Color(0xFFE91E63),
                '${todayEarnings['appointment_count']} appointments',
              ),
              _buildSummaryCard(
                'Total Customers',
                totalCustomers.toString(),
                Icons.people_alt,
                const Color(0xFF9C27B0),
                'Registered users',
              ),
              _buildSummaryCard(
                'Total Services',
                totalServices.toString(),
                Icons.spa,
                const Color(0xFFE91E63),
                'Available services',
              ),
              _buildSummaryCard(
                'This Month',
                '₹${monthlySummary['total_earnings'] ?? 0}',
                Icons.calendar_month,
                const Color(0xFF9C27B0),
                '${monthlySummary['total_appointments'] ?? 0} appointments',
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Refined Bar Chart
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Revenue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    days[value.toInt()],
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                );
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
                        // Map recent 7 days to the chart
                        final targetDate = DateTime.now().subtract(Duration(days: 6 - index));
                        final targetDateStr = DateFormat('yyyy-MM-dd').format(targetDate);
                        
                        double earnings = 0;
                        for (var data in _dailyEarnings) {
                          if (data['date'] == targetDateStr) {
                            earnings = double.tryParse(data['total_earnings']?.toString() ?? '0') ?? 0;
                            break;
                          }
                        }
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: earnings,
                              color: const Color(0xFFE91E63),
                              width: 16,
                              borderRadius: BorderRadius.circular(6),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: const Color(0xFFFCE4EC),
                              ),
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
          const SizedBox(height: 32),

          // Recent Activity
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 16),
                if (provider.appointments.isEmpty)
                  const Text('No recent activity.', style: TextStyle(color: Colors.grey))
                else
                  ...provider.appointments.take(4).map((a) {
                    String dateStr = 'Unknown Date';
                    String timeStr = '';
                    if (a['appointment_date'] != null && a['appointment_date'] != 'null') {
                      try {
                        final pDate = DateTime.parse(a['appointment_date'].toString());
                        dateStr = DateFormat('dd MMM').format(pDate);
                        timeStr = DateFormat('HH:mm').format(pDate);
                      } catch(e) {}
                    }
                    
                    final customerName = a['customer']?['name'] ?? a['customer_name'] ?? 'Unknown Customer';
                    
                    String serviceName = 'Unknown Service';
                    if (a['services'] != null && (a['services'] as List).isNotEmpty) {
                      final firstService = a['services'][0];
                      serviceName = firstService['service']?['name'] ?? 'Service';
                    } else if (a['service_name'] != null) {
                      serviceName = a['service_name'];
                    }
                    
                    final statusColor = a['status'] == 'Completed' ? Colors.green : (a['status'] == 'Cancelled' ? Colors.red : Colors.orange);
                    final iconColor = const Color(0xFF9C27B0);
                    
                    return _buildActivityItem(
                      'Appointment ${a['status'] ?? 'Scheduled'}',
                      '$customerName • $serviceName',
                      '$dateStr at $timeStr',
                      Icons.event_note,
                      iconColor,
                      statusColor,
                    );
                  }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    if (_popularServices.isEmpty) {
      return const Center(child: Text('No service data available', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _popularServices.length,
      itemBuilder: (context, index) {
        final service = _popularServices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
              child: const Icon(Icons.spa, color: Color(0xFFE91E63)),
            ),
            title: Text(service['service_name'] ?? 'Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('${service['appointment_count'] ?? 0} appointments', style: TextStyle(color: Colors.grey[600])),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${service['total_revenue'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${service['percentage'] ?? 0}% share',
                    style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFFE91E63)),
                  onPressed: () {},
                ),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFFE91E63)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMonthlyStat(
                        'Total Revenue',
                        '₹${monthlySummary['total_earnings'] ?? 0}',
                        Icons.account_balance_wallet,
                        Colors.green
                    ),
                    _buildMonthlyStat(
                        'Appointments',
                        '${monthlySummary['total_appointments'] ?? 0}',
                        Icons.event_note,
                        const Color(0xFFE91E63)
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMonthlyStat(
                        'Services',
                        '${monthlySummary['total_services'] ?? 0}',
                        Icons.spa,
                        const Color(0xFF9C27B0)
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
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE91E63) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, color: Colors.green[400], size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color iconColor, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
      ],
    );
  }
}