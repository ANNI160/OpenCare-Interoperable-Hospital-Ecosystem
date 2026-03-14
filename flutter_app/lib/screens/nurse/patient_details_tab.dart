import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/patient_model.dart';

class PatientDetailsTab extends StatefulWidget {
  final int wardNumber;
  final int bedNumber;

  const PatientDetailsTab({
    super.key,
    required this.wardNumber,
    required this.bedNumber,
  });

  @override
  State<PatientDetailsTab> createState() => _PatientDetailsTabState();
}

class _PatientDetailsTabState extends State<PatientDetailsTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isCritical = false;
  bool _isLoading = true;
  bool _isSaving = false;
  PatientModel? _existingPatient;

  List<UserModel> _doctors = [];
  String? _selectedDoctorId;
  String? _selectedDoctorName;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadPatient();
  }

  Future<void> _loadDoctors() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authService = authProvider.authService;
    final doctors = await authService.getAllDoctors();
    if (mounted) {
      setState(() => _doctors = doctors);
    }
  }

  Future<void> _loadPatient() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final patient = await db.getPatientByWardBed(widget.wardNumber, widget.bedNumber);
      if (mounted) {
        setState(() {
          _existingPatient = patient;
          _isLoading = false;
          if (patient != null) {
            _nameController.text = patient.name;
            _ageController.text = patient.age.toString();
            _selectedGender = patient.gender;
            _diagnosisController.text = patient.diagnosisSummary ?? '';
            _allergiesController.text = patient.allergies.join(', ');
            _notesController.text = patient.specialNotes ?? '';
            _isCritical = patient.isCritical;
            _selectedDoctorId = patient.attendingDoctorId;
            _selectedDoctorName = patient.attendingDoctorName;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final db = DatabaseService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      final allergies = _allergiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (_existingPatient != null) {
        // Update existing patient
        final updated = _existingPatient!.copyWith(
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _selectedGender,
          diagnosisSummary: _diagnosisController.text.trim(),
          allergies: allergies,
          specialNotes: _notesController.text.trim(),
          isCritical: _isCritical,
          attendingDoctorId: _selectedDoctorId,
          attendingDoctorName: _selectedDoctorName,
        );
        await db.updatePatient(updated);
      } else {
        // Create new patient
        final patient = PatientModel(
          id: '',
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _selectedGender,
          diagnosisSummary: _diagnosisController.text.trim(),
          wardNumber: widget.wardNumber,
          bedNumber: widget.bedNumber,
          admissionDate: DateTime.now(),
          allergies: allergies,
          specialNotes: _notesController.text.trim(),
          isCritical: _isCritical,
          status: _isCritical ? 'critical' : 'stable',
          attendingDoctorId: _selectedDoctorId,
          attendingDoctorName: _selectedDoctorName,
          assignedNurseId: user?.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await db.addPatient(patient);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existingPatient != null ? 'Patient updated' : 'Patient registered'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadPatient();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _diagnosisController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _triggerEmergency() async {
    final patient = _existingPatient;
    if (patient == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppTheme.criticalRed),
            const SizedBox(width: 8),
            const Text('Trigger Emergency'),
          ],
        ),
        content: Text(
          'This will send a Code Blue alert for ${patient.name} '
          '(Ward ${patient.wardNumber}, Bed ${patient.bedNumber}) to all doctors.\n\n'
          'Are you sure?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.criticalRed),
            child: const Text('TRIGGER CODE BLUE'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final db = DatabaseService();
      final result = await db.triggerEmergency(
        patientId: patient.id,
        patientName: patient.name,
        wardNumber: patient.wardNumber,
        bedNumber: patient.bedNumber,
      );
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.emergency, color: Colors.white),
                SizedBox(width: 8),
                Text('Emergency escalated — doctors notified'),
              ],
            ),
            backgroundColor: AppTheme.criticalRed,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _existingPatient != null
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _existingPatient != null
                      ? AppTheme.primaryColor.withValues(alpha: 0.3)
                      : AppTheme.accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _existingPatient != null ? Icons.edit_note : Icons.person_add,
                    color: _existingPatient != null ? AppTheme.primaryColor : AppTheme.accentColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _existingPatient != null ? 'Edit Patient Details' : 'Register New Patient',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _existingPatient != null ? AppTheme.primaryColor : AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Patient Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Patient Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
            ),

            const SizedBox(height: 16),

            // Age & Gender row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Age required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    items: ['Male', 'Female', 'Other'].map((g) {
                      return DropdownMenuItem(value: g, child: Text(g));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGender = val);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Attending Doctor (dropdown)
            DropdownButtonFormField<String>(
              value: _doctors.any((d) => d.id == _selectedDoctorId) ? _selectedDoctorId : null,
              decoration: const InputDecoration(
                labelText: 'Attending Doctor',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
              items: _doctors.map((doctor) {
                return DropdownMenuItem(
                  value: doctor.id,
                  child: Text('${doctor.name}${doctor.specialization != null ? ' (${doctor.specialization})' : ''}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final doc = _doctors.firstWhere((d) => d.id == val);
                  setState(() {
                    _selectedDoctorId = doc.id;
                    _selectedDoctorName = doc.name;
                  });
                }
              },
              hint: const Text('Select a doctor'),
            ),

            const SizedBox(height: 16),

            // Diagnosis
            TextFormField(
              controller: _diagnosisController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Diagnosis Summary',
                prefixIcon: Icon(Icons.medical_information_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 16),

            // Allergies
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Allergies (comma-separated)',
                prefixIcon: Icon(Icons.warning_amber),
                hintText: 'e.g. Penicillin, Aspirin',
              ),
            ),

            const SizedBox(height: 16),

            // Special Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Special Notes',
                prefixIcon: Icon(Icons.note_alt_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 16),

            // Critical toggle
            SwitchListTile(
              title: const Text('Critical Condition'),
              subtitle: const Text('Mark patient as critical'),
              value: _isCritical,
              onChanged: (val) => setState(() => _isCritical = val),
              activeColor: AppTheme.criticalRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: _isCritical
                  ? AppTheme.criticalRed.withValues(alpha: 0.1)
                  : null,
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(_existingPatient != null ? Icons.save : Icons.person_add),
                label: Text(
                  _existingPatient != null ? 'Update Patient' : 'Register Patient',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            // Emergency escalation button — only for existing patients
            if (_existingPatient != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _triggerEmergency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.criticalRed,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.emergency, size: 28),
                  label: const Text(
                    'CODE BLUE — Emergency',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
