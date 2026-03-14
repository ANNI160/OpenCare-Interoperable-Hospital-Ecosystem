import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];

        // Save session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _accessToken!);
        await prefs.setString('user_role', data['role'] ?? '');
        await prefs.setBool('is_logged_in', true);

        return data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error. Please check server availability.');
    }
  }

  Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String role,
    String? assignedWard,
    String? specialization,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signupUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'employee_id': employeeId,
          'role': role,
          'assigned_ward': assignedWard,
          'specialization': specialization,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _accessToken!);
        await prefs.setString('user_role', data['role'] ?? '');
        await prefs.setBool('is_logged_in', true);

        return data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Sign up failed');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error. Please check server availability.');
    }
  }

  Future<UserModel?> getUserData() async {
    if (_accessToken == null) return null;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.meUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (_accessToken != null) {
        await http.post(
          Uri.parse(ApiConfig.logoutUrl),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );
      }
    } catch (_) {}
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    if (loggedIn) {
      _accessToken = prefs.getString('access_token');
    }
    return loggedIn && _accessToken != null;
  }

  Future<String?> getSavedUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> updateUserStatus({required bool isOnline}) async {
    if (_accessToken == null) return;
    try {
      await http.patch(
        Uri.parse(ApiConfig.meUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_online': isOnline}),
      );
    } catch (_) {}
  }

  Future<List<UserModel>> getAllDoctors() async {
    if (_accessToken == null) return [];
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.doctorsUrl),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => UserModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<UserModel>> getAllNurses() async {
    if (_accessToken == null) return [];
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.nursesUrl),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => UserModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
