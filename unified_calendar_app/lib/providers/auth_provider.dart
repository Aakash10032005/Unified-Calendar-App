import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_calendar_app/providers/calendar_provider.dart'; // Import CalendarProvider
import 'package:provider/provider.dart';


class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userId; // Our internal user ID from the backend
  String? _userEmail; // User's email

  // Base URL for your backend API (update for local vs deployed)
  // For Android Emulator, use 10.0.2.2 instead of localhost
  // For web/desktop, 'localhost' is fine
  final String _baseUrl = "http://10.0.2.2:3000/api"; // Corrected port to 3000 // UPDATE THIS FOR DEPLOYMENT TO RENDER

  String? get token => _token;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String get baseUrl => _baseUrl;


  AuthProvider() {
    _loadAuthData(); // Load auth data on initialization
  }

  // Attempts to load authentication data (token, userId, userEmail) from shared preferences.
  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _userEmail = prefs.getString('userEmail');
    notifyListeners(); // Notify listeners that auth state might have changed
  }

  // Persists authentication data to shared preferences.
  Future<void> _saveAuthData(String token, String userId, String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    await prefs.setString('userEmail', userEmail);
    _token = token;
    _userId = userId;
    _userEmail = userEmail;
    notifyListeners();
  }

  // Clears authentication data from shared preferences and resets state.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    _token = null;
    _userId = null;
    _userEmail = null;
    notifyListeners();

    // Optionally, clear calendar data as well on logout
    // Note: You must ensure CalendarProvider is accessible (e.g., via Provider.of in main)
    // If context is not available here, this would need to be handled where logout is called
  }

  // Registers a new user with the backend.
  Future<void> register(String email, String password, {BuildContext? context}) async {
    final url = Uri.parse('$_baseUrl/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        _saveAuthData(responseData['token'], responseData['userId'], responseData['email']);
        // Optionally fetch initial calendar data after login
        if (context != null) {
          await Provider.of<CalendarProvider>(context, listen: false).fetchEvents(context: context);
        }
      } else {
        throw Exception(responseData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration error: $e'); // Debug print
      throw Exception('Failed to register: $e');
    }
  }

  // Logs in an existing user with the backend.
  Future<void> login(String email, String password, {BuildContext? context}) async { // Added named context parameter
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _saveAuthData(responseData['token'], responseData['userId'], responseData['email']);
        // Fetch initial calendar data after successful login
        if (context != null) {
          await Provider.of<CalendarProvider>(context, listen: false).fetchEvents(context: context);
        }
      } else {
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e'); // Debug print
      throw Exception('Failed to log in: $e');
    }
  }
}
