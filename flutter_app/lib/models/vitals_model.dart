import '../config/constants.dart';

class VitalsModel {
  final String id;
  final String patientId;
  final String recordedById;
  final String recordedByName;
  final DateTime timestamp;
  final int? heartRate;
  final int? systolicBP;
  final int? diastolicBP;
  final double? oxygenSaturation;
  final double? temperature;
  final int? respiratoryRate;
  final double? glucoseLevel;
  final String? notes;
  final Map<String, bool> alerts;

  VitalsModel({
    required this.id,
    required this.patientId,
    required this.recordedById,
    required this.recordedByName,
    required this.timestamp,
    this.heartRate,
    this.systolicBP,
    this.diastolicBP,
    this.oxygenSaturation,
    this.temperature,
    this.respiratoryRate,
    this.glucoseLevel,
    this.notes,
    this.alerts = const {},
  });

  String get bloodPressure => '${systolicBP ?? '-'}/${diastolicBP ?? '-'}';
  bool get hasAnyAlert => alerts.values.any((v) => v);

  bool get isHeartRateAbnormal => alerts['heart_rate'] ?? false;
  bool get isOxygenLow => alerts['oxygen_saturation'] ?? false;
  bool get isTemperatureAbnormal => alerts['temperature'] ?? false;
  bool get isRespiratoryAbnormal => alerts['respiratory_rate'] ?? false;
  bool get isGlucoseAbnormal => alerts['glucose_level'] ?? false;
  bool get isBPAbnormal => (alerts['systolic_bp'] ?? false) || (alerts['diastolic_bp'] ?? false);

  static bool isHeartRateNormal(int val) => val >= 60 && val <= 100;
  static bool isOxygenNormal(double val) => val >= 95 && val <= 100;
  static bool isTemperatureNormal(double val) => val >= 36.1 && val <= 37.2;
  static bool isRespiratoryRateNormal(int val) => val >= 12 && val <= 20;
  static bool isGlucoseNormal(double val) => val >= 70 && val <= 140;
  static bool isSystolicBPNormal(int val) => val >= 90 && val <= 120;
  static bool isDiastolicBPNormal(int val) => val >= 60 && val <= 80;

  Map<String, bool> calculateAlerts() {
    return {
      'heart_rate': heartRate != null && !isHeartRateNormal(heartRate!),
      'oxygen_saturation': oxygenSaturation != null && !isOxygenNormal(oxygenSaturation!),
      'temperature': temperature != null && !isTemperatureNormal(temperature!),
      'respiratory_rate': respiratoryRate != null && !isRespiratoryRateNormal(respiratoryRate!),
      'glucose_level': glucoseLevel != null && !isGlucoseNormal(glucoseLevel!),
      'systolic_bp': systolicBP != null && !isSystolicBPNormal(systolicBP!),
      'diastolic_bp': diastolicBP != null && !isDiastolicBPNormal(diastolicBP!),
    };
  }

  factory VitalsModel.fromJson(Map<String, dynamic> json) {
    return VitalsModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      recordedById: json['recorded_by_id'] ?? '',
      recordedByName: json['recorded_by_name'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      heartRate: json['heart_rate'],
      systolicBP: json['systolic_bp'],
      diastolicBP: json['diastolic_bp'],
      oxygenSaturation: json['oxygen_saturation']?.toDouble(),
      temperature: json['temperature']?.toDouble(),
      respiratoryRate: json['respiratory_rate'],
      glucoseLevel: json['glucose_level']?.toDouble(),
      notes: json['notes'],
      alerts: (json['alerts'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as bool)) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'heart_rate': heartRate,
    'systolic_bp': systolicBP,
    'diastolic_bp': diastolicBP,
    'oxygen_saturation': oxygenSaturation,
    'temperature': temperature,
    'respiratory_rate': respiratoryRate,
    'glucose_level': glucoseLevel,
    'notes': notes,
  };
}
