import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/patient_model.dart';
import '../models/vitals_model.dart';
import '../models/medication_model.dart';
import '../models/medication_reaction_model.dart';
import '../models/message_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';

/// Central API service replacing Firestore DatabaseService.
/// All methods use HTTP calls to the FastAPI backend.
class DatabaseService {
  final String _token;

  // Static token for easy access from screens
  static String? _globalToken;
  static void setGlobalToken(String token) => _globalToken = token;

  DatabaseService([String? token]) : _token = token ?? _globalToken ?? '';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  // ─── User Operations ──────────────────────
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await http.patch(
      Uri.parse(ApiConfig.meUrl),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  Future<void> deleteUser(String userId) async {
    await http.delete(
      Uri.parse('${ApiConfig.staffUrl}/$userId'),
      headers: _headers,
    );
  }

  // ─── Hospital Config ──────────────────────
  Future<Map<String, dynamic>> getHospitalConfig() async {
    final response = await http.get(
      Uri.parse(ApiConfig.configUrl),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'total_wards': 5, 'beds_per_ward': 10};
  }

  Future<void> updateHospitalConfig({
    required int totalWards,
    required int bedsPerWard,
  }) async {
    await http.put(
      Uri.parse(ApiConfig.configUrl),
      headers: _headers,
      body: jsonEncode({
        'total_wards': totalWards,
        'beds_per_ward': bedsPerWard,
      }),
    );
  }

  // ─── Patient Operations ───────────────────
  Future<List<PatientModel>> getAllPatients() async {
    final response = await http.get(
      Uri.parse(ApiConfig.patientsUrl),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => PatientModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<List<PatientModel>> getPatientsForWard(int wardNumber) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.patientsUrl}?ward_number=$wardNumber'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => PatientModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<List<PatientModel>> getPatientsForDoctor(String doctorId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.patientsUrl}?doctor_id=$doctorId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final patients = data.map((j) => PatientModel.fromJson(j)).toList();
      patients.sort((a, b) {
        final wardCmp = a.wardNumber.compareTo(b.wardNumber);
        return wardCmp != 0 ? wardCmp : a.bedNumber.compareTo(b.bedNumber);
      });
      return patients;
    }
    return [];
  }

  Future<List<PatientModel>> getPatientsByWard(int wardNumber) async {
    final patients = await getPatientsForWard(wardNumber);
    patients.sort((a, b) => a.bedNumber.compareTo(b.bedNumber));
    return patients;
  }

  Future<PatientModel?> getPatient(String patientId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.patientsUrl}/$patientId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return PatientModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<PatientModel?> getPatientByWardBed(int wardNumber, int bedNumber) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.patientsUrl}/ward/$wardNumber/bed/$bedNumber'),
      headers: _headers,
    );
    if (response.statusCode == 200 && response.body != 'null') {
      return PatientModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<String> addPatient(PatientModel patient) async {
    final response = await http.post(
      Uri.parse(ApiConfig.patientsUrl),
      headers: _headers,
      body: jsonEncode(patient.toJson()),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    }
    throw Exception('Failed to add patient');
  }

  Future<void> updatePatient(PatientModel patient) async {
    await http.put(
      Uri.parse('${ApiConfig.patientsUrl}/${patient.id}'),
      headers: _headers,
      body: jsonEncode(patient.toJson()),
    );
  }

  Future<PatientModel?> getMyPatientProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.patientPortalUrl}/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return PatientModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // ─── Vitals Operations ────────────────────
  Future<List<VitalsModel>> getVitalsForPatient(String patientId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.vitalsUrl}/$patientId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => VitalsModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<VitalsModel?> getLatestVitals(String patientId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.vitalsUrl}/$patientId/latest'),
      headers: _headers,
    );
    if (response.statusCode == 200 && response.body != 'null') {
      return VitalsModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<void> addVitals(VitalsModel vitals) async {
    await http.post(
      Uri.parse(ApiConfig.vitalsUrl),
      headers: _headers,
      body: jsonEncode(vitals.toJson()),
    );
  }

  // ─── Medication Operations ────────────────
  Future<List<MedicationModel>> getMedicationsForPatient(String patientId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.medicationsUrl}/$patientId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => MedicationModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<List<MedicationModel>> getPendingMedications(String patientId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.medicationsUrl}/$patientId/pending'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => MedicationModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<void> addMedication(MedicationModel medication) async {
    await http.post(
      Uri.parse(ApiConfig.medicationsUrl),
      headers: _headers,
      body: jsonEncode(medication.toJson()),
    );
  }

  Future<List<MedicationModel>> getMyPortalMedications() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.patientPortalUrl}/me/medications'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => MedicationModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<List<MedicationReactionModel>> getMyMedicationReactions() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.patientPortalUrl}/me/reactions'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => MedicationReactionModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<void> reportMedicationReaction(MedicationReactionModel reaction) async {
    await http.post(
      Uri.parse('${ApiConfig.patientPortalUrl}/me/reactions'),
      headers: _headers,
      body: jsonEncode(reaction.toCreateJson()),
    );
  }

  Future<void> administerMedication({
    required String medicationId,
    required String nurseId,
    required String nurseName,
  }) async {
    await http.patch(
      Uri.parse('${ApiConfig.medicationsUrl}/$medicationId/administer'),
      headers: _headers,
    );
  }

  // ─── Message Operations ───────────────────
  Future<List<MessageModel>> getMessagesForPatient(String patientId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.messagesUrl}/$patientId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => MessageModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<int> getUnreadMessageCount(String userId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.messagesUrl}/unread/count'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['unread_count'] ?? 0;
    }
    return 0;
  }

  Future<void> sendMessage(MessageModel message) async {
    await http.post(
      Uri.parse(ApiConfig.messagesUrl),
      headers: _headers,
      body: jsonEncode(message.toJson()),
    );
  }

  Future<List<MessageModel>> getMyPortalMessages() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.patientPortalUrl}/me/messages'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => MessageModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<void> sendPortalMessage({
    required String content,
    String type = 'text',
  }) async {
    await http.post(
      Uri.parse('${ApiConfig.patientPortalUrl}/me/messages'),
      headers: _headers,
      body: jsonEncode({
        'content': content,
        'type': type,
      }),
    );
  }

  // ─── Appointment Operations ───────────────
  Future<List<AppointmentModel>> getAppointmentsForPatient(String patientId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.appointmentsUrl}/patient/$patientId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => AppointmentModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<List<AppointmentModel>> getMyPortalAppointments() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.patientPortalUrl}/me/appointments'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => AppointmentModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<void> createAppointment(AppointmentModel appointment) async {
    await http.post(
      Uri.parse(ApiConfig.appointmentsUrl),
      headers: _headers,
      body: jsonEncode(appointment.toCreateJson()),
    );
  }

  Future<void> markMessageAsRead(String messageId) async {
    await http.patch(
      Uri.parse('${ApiConfig.messagesUrl}/$messageId/read'),
      headers: _headers,
    );
  }

  // ─── Task Operations ──────────────────────
  Future<List<TaskModel>> getTasksForWard(int wardNumber) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.tasksUrl}/ward/$wardNumber'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => TaskModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<void> addTask(TaskModel task) async {
    await http.post(
      Uri.parse(ApiConfig.tasksUrl),
      headers: _headers,
      body: jsonEncode(task.toJson()),
    );
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required bool isCompleted,
    String? completedByNurseId,
    String? completedByNurseName,
  }) async {
    await http.patch(
      Uri.parse('${ApiConfig.tasksUrl}/$taskId'),
      headers: _headers,
      body: jsonEncode({'is_completed': isCompleted}),
    );
  }

  Future<void> deleteTask(String taskId) async {
    await http.delete(
      Uri.parse('${ApiConfig.tasksUrl}/$taskId'),
      headers: _headers,
    );
  }

  // ─── Audit Log ────────────────────────────
  Future<void> addAuditLog({
    required String userId,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await http.post(
        Uri.parse(ApiConfig.auditUrl),
        headers: _headers,
        body: jsonEncode({
          'action': action,
          'entity_type': entityType,
          'entity_id': entityId,
          'metadata': metadata,
        }),
      );
    } catch (_) {
      // Silent — audit logging is non-critical
    }
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? entityType,
    String? userId,
    int limit = 100,
  }) async {
    final params = <String, String>{};
    if (entityType != null) params['entity_type'] = entityType;
    if (userId != null) params['user_id'] = userId;
    params['limit'] = limit.toString();
    final uri = Uri.parse(ApiConfig.auditUrl).replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  // ─── Emergency Escalation ─────────────────
  Future<Map<String, dynamic>?> triggerEmergency({
    required String patientId,
    required String patientName,
    required int wardNumber,
    required int bedNumber,
    String severity = 'critical',
    String reason = 'Code Blue',
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.emergenciesUrl),
      headers: _headers,
      body: jsonEncode({
        'patient_id': patientId,
        'patient_name': patientName,
        'ward_number': wardNumber,
        'bed_number': bedNumber,
        'severity': severity,
        'reason': reason,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getActiveEmergencies() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.emergenciesUrl}/active'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getEmergencies({String? status}) async {
    final uri = status != null
        ? Uri.parse('${ApiConfig.emergenciesUrl}?status=$status')
        : Uri.parse(ApiConfig.emergenciesUrl);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<void> acknowledgeEmergency(String emergencyId) async {
    await http.patch(
      Uri.parse('${ApiConfig.emergenciesUrl}/$emergencyId/acknowledge'),
      headers: _headers,
    );
  }

  Future<void> resolveEmergency(String emergencyId, {String? notes}) async {
    await http.patch(
      Uri.parse('${ApiConfig.emergenciesUrl}/$emergencyId/resolve'),
      headers: _headers,
      body: jsonEncode({'resolution_notes': notes}),
    );
  }
}
