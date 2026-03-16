import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use your local IP address
  static const String baseUrl = 'http://10.16.11.198:8000';

  // For Android Emulator (comment this out)
  // static const String baseUrl = 'http://10.0.2.2:8000';

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return null;
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== CUSTOMER APIS ====================
  Future<List<dynamic>> getCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/'),
        headers: {'Content-Type': 'application/json'},
      );
      final result = await _handleResponse(response);
      return result as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(customerData),
      );
      final result = await _handleResponse(response);
      return result as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<Map<String, dynamic>> updateCustomer(int id, Map<String, dynamic> customerData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/customers/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(customerData),
      );
      final result = await _handleResponse(response);
      return result as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/customers/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      await _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  // ==================== SERVICE APIS ====================
  Future<List<dynamic>> getServices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/'),
        headers: {'Content-Type': 'application/json'},
      );
      final result = await _handleResponse(response);
      return result as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load services: $e');
    }
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> serviceData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/services/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(serviceData),
      );
      final result = await _handleResponse(response);
      return result as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  Future<Map<String, dynamic>> updateService(int id, Map<String, dynamic> serviceData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/services/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(serviceData),
      );
      final result = await _handleResponse(response);
      return result as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  Future<void> deleteService(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/services/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      await _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete service: $e');
    }
  }

  // ==================== APPOINTMENT APIS ====================
  Future<List<dynamic>> getAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/appointments/'),
        headers: {'Content-Type': 'application/json'},
      );
      final result = await _handleResponse(response);
      return result as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load appointments: $e');
    }
  }

  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> appointmentData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(appointmentData),
      );
      final result = await _handleResponse(response);
      return result as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  Future<Map<String, dynamic>> updatePayment(int appointmentId, String paymentStatus, {String? paymentMethod}) async {
    try {
      String url = '$baseUrl/appointments/$appointmentId/payment?payment_status=$paymentStatus';
      if (paymentMethod != null) {
        url += '&payment_method=$paymentMethod';
      }

      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      final result = await _handleResponse(response);
      return result as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  // ==================== ANALYTICS APIS ====================
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/'),
        headers: {'Content-Type': 'application/json'},
      );
      final result = await _handleResponse(response);
      return result as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load dashboard: $e');
    }
  }

  Future<List<dynamic>> getServicePopularity(int days) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/service-popularity/?days=$days'),
        headers: {'Content-Type': 'application/json'},
      );
      final result = await _handleResponse(response);
      return result as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load service popularity: $e');
    }
  }
}