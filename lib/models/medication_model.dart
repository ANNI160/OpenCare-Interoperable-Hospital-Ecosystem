class MedicationModel {
  final String id;
  final String patientId;
  final String name;
  final String dosage;
  final String route;
  final String frequency;
  final DateTime? scheduledTime;
  final DateTime? administeredTime;
  final String? administeredById;
  final String? administeredByName;
  final bool isInjection;
  final bool isAdministered;
  final String? notes;
  final String prescribedById;
  final String prescribedByName;
  final DateTime createdAt;

  MedicationModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    this.route = 'oral',
    this.frequency = 'once',
    this.scheduledTime,
    this.administeredTime,
    this.administeredById,
    this.administeredByName,
    this.isInjection = false,
    this.isAdministered = false,
    this.notes,
    required this.prescribedById,
    required this.prescribedByName,
    required this.createdAt,
  });

  bool get isPending => !isAdministered && scheduledTime != null && DateTime.now().isAfter(scheduledTime!);
  bool get isOverdue => !isAdministered && scheduledTime != null && DateTime.now().difference(scheduledTime!).inMinutes > 30;

  String get routeLabel {
    switch (route) {
      case 'oral': return 'Oral';
      case 'iv': return 'IV (Intravenous)';
      case 'im': return 'IM (Intramuscular)';
      case 'sc': return 'SC (Subcutaneous)';
      case 'topical': return 'Topical';
      default: return route;
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'once': return 'Once';
      case 'bid': return 'Twice Daily';
      case 'tid': return 'Three Times Daily';
      case 'qid': return 'Four Times Daily';
      case 'prn': return 'As Needed';
      default: return frequency;
    }
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      route: json['route'] ?? 'oral',
      frequency: json['frequency'] ?? 'once',
      scheduledTime: json['scheduled_time'] != null ? DateTime.parse(json['scheduled_time']) : null,
      administeredTime: json['administered_time'] != null ? DateTime.parse(json['administered_time']) : null,
      administeredById: json['administered_by_id'],
      administeredByName: json['administered_by_name'],
      isInjection: json['is_injection'] ?? false,
      isAdministered: json['is_administered'] ?? false,
      notes: json['notes'],
      prescribedById: json['prescribed_by_id'] ?? '',
      prescribedByName: json['prescribed_by_name'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'name': name,
    'dosage': dosage,
    'route': route,
    'frequency': frequency,
    'scheduled_time': scheduledTime?.toIso8601String(),
    'is_injection': isInjection,
    'notes': notes,
  };
}
