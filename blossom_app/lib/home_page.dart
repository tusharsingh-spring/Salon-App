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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.fetchDashboardData();
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuAction(
    BuildContext context,
    String label,
    IconData icon,
    List<Color> gradientColors,
    Widget destination,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ));
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final todayEarnings = provider.dashboardData['today_earnings'] ??
        {'total_earnings': 0, 'appointment_count': 0};

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Good Morning,',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s your salon summary today',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                if (provider.isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.pink)))
                else if (provider.dashboardData.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDashboardCard(
                            'Today\'s Earnings',
                            '₹${todayEarnings['total_earnings']}',
                            '${todayEarnings['appointment_count']} appointments',
                            Icons.account_balance_wallet,
                            const Color(0xFFE91E63),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDashboardCard(
                            'Total Customers',
                            '${provider.dashboardData['total_customers'] ?? 0}',
                            'Registered in app',
                            Icons.people_alt,
                            const Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildMenuAction(
                        context,
                        'Customers',
                        Icons.group,
                        [const Color(0xFFFF8A65), const Color(0xFFF4511E)],
                        const CustomersPage(),
                      ),
                      _buildMenuAction(
                        context,
                        'Services',
                        Icons.spa,
                        [const Color(0xFF64B5F6), const Color(0xFF1E88E5)],
                        const ServicesPage(),
                      ),
                      _buildMenuAction(
                        context,
                        'Appointments',
                        Icons.calendar_month,
                        [const Color(0xFFBA68C8), const Color(0xFF8E24AA)],
                        const AppointmentsPage(),
                      ),
                      _buildMenuAction(
                        context,
                        'Analytics',
                        Icons.bar_chart,
                        [const Color(0xFFF06292), const Color(0xFFE91E63)],
                        const AnalyticsPage(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}