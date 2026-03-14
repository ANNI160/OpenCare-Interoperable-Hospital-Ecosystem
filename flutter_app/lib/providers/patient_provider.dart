import 'package:flutter/foundation.dart';
import '../models/patient_model.dart';
import '../models/vitals_model.dart';
import '../models/medication_model.dart';
import '../services/database_service.dart';

class PatientProvider extends ChangeNotifier {
  PatientModel? _selectedPatient;
  List<PatientModel> _patients = [];
  List<VitalsModel> _vitals = [];
  List<MedicationModel> _medications = [];
  bool _isLoading = false;
  String? _errorMessage;

  PatientModel? get selectedPatient => _selectedPatient;
  List<PatientModel> get patients => _patients;
  List<VitalsModel> get vitals => _vitals;
  List<MedicationModel> get medications => _medications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void selectPatient(PatientModel patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

  void clearSelectedPatient() {
    _selectedPatient = null;
    notifyListeners();
  }

  Future<void> addPatient(DatabaseService db, PatientModel patient) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await db.addPatient(patient);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePatient(DatabaseService db, PatientModel patient) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await db.updatePatient(patient);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVitals(DatabaseService db, VitalsModel vitals) async {
    _isLoading = true;
    notifyListeners();

    try {
      await db.addVitals(vitals);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMedication(DatabaseService db, MedicationModel medication) async {
    _isLoading = true;
    notifyListeners();

    try {
      await db.addMedication(medication);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> administerMedication(DatabaseService db, {
    required String medicationId,
    required String nurseId,
    required String nurseName,
  }) async {
    try {
      await db.administerMedication(
        medicationId: medicationId,
        nurseId: nurseId,
        nurseName: nurseName,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<VitalsModel?> getLatestVitals(DatabaseService db, String patientId) async {
    return await db.getLatestVitals(patientId);
  }

  Future<List<MedicationModel>> getPendingMedications(DatabaseService db, String patientId) async {
    return await db.getPendingMedications(patientId);
  }
}
