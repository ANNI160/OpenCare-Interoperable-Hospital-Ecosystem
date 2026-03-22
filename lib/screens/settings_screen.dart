import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _wardController;
  late TextEditingController _specializationController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
    _wardController = TextEditingController(text: user?.assignedWard);
    _specializationController = TextEditingController(text: user?.specialization);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _wardController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) return;

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'assigned_ward': _wardController.text.trim(),
      };
      if (user.isDoctor) {
        updates['specialization'] = _specializationController.text.trim();
      }

      await _databaseService.updateUser(user.id, updates);
      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), backgroundColor: AppTheme.stableGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.criticalRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _wardController,
                decoration: const InputDecoration(labelText: 'Assigned Ward', prefixIcon: Icon(Icons.local_hospital_outlined)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              if (user?.isDoctor ?? false) ...[
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(labelText: 'Specialization', prefixIcon: Icon(Icons.medical_services_outlined)),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
