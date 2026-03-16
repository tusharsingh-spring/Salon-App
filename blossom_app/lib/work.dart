import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.fetchAppointments();
    if (mounted) {
      setState(() {});
    }
  }

  List<dynamic> _getFilteredAppointments(String filter) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final now = DateTime.now();

    switch (filter) {
      case 'today':
        return provider.appointments.where((a) {
          final date = DateTime.parse(a['appointment_date']);
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();
      case 'upcoming':
        return provider.appointments.where((a) {
          final date = DateTime.parse(a['appointment_date']);
          return date.isAfter(now) && a['status'] != 'Completed';
        }).toList();
      case 'past':
        return provider.appointments.where((a) {
          final date = DateTime.parse(a['appointment_date']);
          return date.isBefore(now) || a['status'] == 'Completed';
        }).toList();
      default:
        return provider.appointments;
    }
  }

  Future<void> _addAppointment(Map<String, dynamic> appointmentData) async {
    if (!mounted) return;
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
      await provider.addAppointment(appointmentData);
      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully'),
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

  Future<void> _updatePayment(int id, String status) async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);

    try {
      await provider.updateAppointmentPayment(id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment marked as $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddDialog() {
    int? selectedCustomerId;
    int? selectedServiceId;
    TimeOfDay? selectedTime;
    DateTime? selectedDate = DateTime.now();

    final provider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Select Customer',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedCustomerId,
                      items: provider.customers.map((customer) {
                        return DropdownMenuItem<int>(
                          value: customer['id'] as int,
                          child: Text(customer['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCustomerId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Select Service',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedServiceId,
                      items: provider.services.map((service) {
                        return DropdownMenuItem<int>(
                          value: service['id'] as int,
                          child: Text('${service['name']} - ₹${service['price']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedServiceId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('dd MMM yyyy').format(selectedDate!)),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(selectedTime?.format(context) ?? 'Select Time'),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedCustomerId != null &&
                        selectedServiceId != null &&
                        selectedTime != null) {
                      Navigator.pop(dialogContext);

                      final appointmentData = {
                        'customer_id': selectedCustomerId,
                        'service_id': selectedServiceId,
                        'appointment_date': selectedDate!.toIso8601String(),
                        'time': selectedTime!.format(context),
                        'status': 'Scheduled',
                        'payment_status': 'Pending',
                      };
                      _addAppointment(appointmentData);
                    }
                  },
                  child: const Text('Book'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDetailsDialog(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Appointment #${appointment['id']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(appointment['customer_name'] ?? 'Customer'),
                subtitle: const Text('Customer'),
              ),
              ListTile(
                leading: const Icon(Icons.spa),
                title: Text(appointment['service_name'] ?? 'Service'),
                subtitle: const Text('Service'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd MMM yyyy').format(
                    DateTime.parse(appointment['appointment_date'])
                )),
                subtitle: const Text('Date'),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(appointment['time'] ?? ''),
                subtitle: const Text('Time'),
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: Text(appointment['payment_status'] ?? ''),
                subtitle: const Text('Payment Status'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: appointment['payment_status'] == 'Paid'
                        ? Colors.green
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment['payment_status'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (appointment['payment_status'] != 'Paid')
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _updatePayment(appointment['id'], 'Paid');
                },
                child: const Text('Mark Paid'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList(_getFilteredAppointments('today')),
          _buildAppointmentList(_getFilteredAppointments('upcoming')),
          _buildAppointmentList(_getFilteredAppointments('past')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: provider.customers.isNotEmpty && provider.services.isNotEmpty
            ? _showAddDialog
            : null,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppointmentList(List<dynamic> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment['customer_name'] ?? 'Customer',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment['status'] ?? '',
                    style: TextStyle(
                      color: _getStatusColor(appointment['status'] ?? ''),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(appointment['service_name'] ?? 'Service'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('dd MMM').format(DateTime.parse(appointment['appointment_date']))} at ${appointment['time']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${appointment['price'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment['payment_status'] ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: appointment['payment_status'] == 'Paid' ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => _showDetailsDialog(appointment),
          ),
        );
      },
    );
  }
}