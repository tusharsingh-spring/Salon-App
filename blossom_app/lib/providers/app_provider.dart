import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _customers = [];
  List<dynamic> _services = [];
  List<dynamic> _appointments = [];
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<dynamic> get customers => _customers;
  List<dynamic> get services => _services;
  List<dynamic> get appointments => _appointments;
  Map<String, dynamic> get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // ==================== CUSTOMER METHODS ====================
  Future<void> fetchCustomers() async {
    _setLoading(true);
    try {
      _customers = await _apiService.getCustomers();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCustomer(Map<String, dynamic> customerData) async {
    _setLoading(true);
    try {
      await _apiService.createCustomer(customerData);
      await fetchCustomers();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCustomer(int id, Map<String, dynamic> customerData) async {
    _setLoading(true);
    try {
      await _apiService.updateCustomer(id, customerData);
      await fetchCustomers();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCustomer(int id) async {
    _setLoading(true);
    try {
      await _apiService.deleteCustomer(id);
      await fetchCustomers();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== SERVICE METHODS ====================
  Future<void> fetchServices() async {
    _setLoading(true);
    try {
      _services = await _apiService.getServices();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addService(Map<String, dynamic> serviceData) async {
    _setLoading(true);
    try {
      await _apiService.createService(serviceData);
      await fetchServices();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateService(int id, Map<String, dynamic> serviceData) async {
    _setLoading(true);
    try {
      await _apiService.updateService(id, serviceData);
      await fetchServices();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteService(int id) async {
    _setLoading(true);
    try {
      await _apiService.deleteService(id);
      await fetchServices();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== APPOINTMENT METHODS ====================
  Future<void> fetchAppointments() async {
    _setLoading(true);
    try {
      _appointments = await _apiService.getAppointments();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAppointment(Map<String, dynamic> appointmentData) async {
    _setLoading(true);
    try {
      await _apiService.createAppointment(appointmentData);
      await fetchAppointments();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAppointment(int id) async {
    _setLoading(true);
    try {
      await _apiService.deleteAppointment(id);
      await fetchAppointments();
      await fetchDashboardData(); // Refetch analytics since an appointment was deleted
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAppointmentPayment(int id, String paymentStatus, {String? paymentMethod}) async {
    _setLoading(true);
    try {
      await _apiService.updatePayment(id, paymentStatus, paymentMethod: paymentMethod);
      await fetchAppointments();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== DASHBOARD METHODS ====================
  Future<void> fetchDashboardData() async {
    _setLoading(true);
    try {
      _dashboardData = await _apiService.getDashboardSummary();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}