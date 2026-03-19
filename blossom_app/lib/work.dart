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
    await provider.fetchCustomers();
    await provider.fetchServices();
    if (mounted) {
      setState(() {});
    }
  }

  List<dynamic> _getFilteredAppointments(String filter) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final now = DateTime.now();

    DateTime? _tryParseDate(dynamic dateString) {
      if (dateString == null || dateString == 'null') return null;
      try {
        return DateTime.parse(dateString.toString());
      } catch (e) {
        return null;
      }
    }

    switch (filter) {
      case 'today':
        return provider.appointments.where((a) {
          final date = _tryParseDate(a['appointment_date']);
          if (date == null) return false;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();
      case 'upcoming':
        return provider.appointments.where((a) {
          final date = _tryParseDate(a['appointment_date']);
          if (date == null) return false;
          return date.isAfter(now) && a['status'] != 'Completed';
        }).toList();
      case 'past':
        return provider.appointments.where((a) {
          final date = _tryParseDate(a['appointment_date']);
          if (date == null) return false;
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

  Future<void> _deleteAppointment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: const Text('Are you sure you want to delete this appointment?'),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await provider.deleteAppointment(id);
      if (!mounted) return;
      Navigator.pop(context); // close progress
      await _loadAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close progress
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
                        final price = service['base_price']?.toString() ?? service['price']?.toString() ?? '0';
                        return DropdownMenuItem<int>(
                          value: service['id'] as int,
                          child: Text('${service['name']} - ₹$price'),
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

                      // Combine date and time
                      final dateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );

                      // Find the selected service to get the price
                      final selectedService = provider.services.firstWhere((s) => s['id'] == selectedServiceId, orElse: () => {});
                      final price = double.tryParse(selectedService['base_price']?.toString() ?? selectedService['price']?.toString() ?? '0') ?? 0.0;

                      final appointmentData = {
                        'customer_id': selectedCustomerId,
                        'appointment_date': dateTime.toIso8601String(),
                        'payment_status': 'Pending',
                        'services': [
                          {
                            'service_id': selectedServiceId,
                            'price_charged': price,
                          }
                        ]
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
    final customerName = appointment['customer']?['name'] ?? appointment['customer_name'] ?? 'Unknown Customer';
    
    String serviceName = 'Unknown Service';
    if (appointment['services'] != null && (appointment['services'] as List).isNotEmpty) {
      final firstService = appointment['services'][0];
      serviceName = firstService['service']?['name'] ?? 'Service';
    } else if (appointment['service_name'] != null) {
      serviceName = appointment['service_name'];
    }

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
                title: Text(customerName),
                subtitle: const Text('Customer'),
              ),
              ListTile(
                leading: const Icon(Icons.spa),
                title: Text(serviceName),
                subtitle: const Text('Service'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(appointment['appointment_date'] != null && appointment['appointment_date'] != 'null' ? 
                  ((){
                    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(appointment['appointment_date'].toString())); }
                    catch(e) { return appointment['appointment_date'].toString(); }
                  })() : 'Unknown Date'
                ),
                subtitle: const Text('Date'),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(appointment['time'] ?? 'No Time'),
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
                child: const Text('Mark Paid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteAppointment(appointment['id']);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
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
        
        final customerName = appointment['customer']?['name'] ?? appointment['customer_name'] ?? 'Unknown Customer';
        
        String serviceName = 'Unknown Service';
        if (appointment['services'] != null && (appointment['services'] as List).isNotEmpty) {
          final firstService = appointment['services'][0];
          serviceName = firstService['service']?['name'] ?? 'Service';
        } else if (appointment['service_name'] != null) {
          serviceName = appointment['service_name'];
        }

        final price = appointment['final_amount']?.toString() ?? appointment['total_amount']?.toString() ?? appointment['price']?.toString() ?? '0';

        return Dismissible(
          key: Key(appointment['id'].toString()),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Appointment'),
                content: const Text('Are you sure you want to delete this appointment?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              final provider = Provider.of<AppProvider>(context, listen: false);
              try {
                await provider.deleteAppointment(appointment['id']);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment deleted'), backgroundColor: Colors.green),
                );
                return true;
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
                return false;
              }
            }
            return false;
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),
          child: Container(
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
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCE4EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_note, color: Color(0xFFE91E63)),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment['status'] ?? '').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment['status'] ?? '',
                      style: TextStyle(
                        color: _getStatusColor(appointment['status'] ?? ''),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(serviceName, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${appointment['appointment_date'] != null && appointment['appointment_date'] != 'null' ? ((){
                          try { return DateFormat('dd MMM').format(DateTime.parse(appointment['appointment_date'].toString())); }
                          catch(e) { return 'Date Error'; }
                        })() : 'No Date'} at ${appointment['time'] ?? 'No Time'}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                    '₹${(price == 'null') ? 0 : price}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE91E63)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: appointment['payment_status'] == 'Paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appointment['payment_status'] ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: appointment['payment_status'] == 'Paid' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () => _showDetailsDialog(appointment),
            ),
          ),
        );
      },
    );
  }
}