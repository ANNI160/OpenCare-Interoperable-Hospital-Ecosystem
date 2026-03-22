class MedicationReactionModel {
  final String id;
  final String medicationId;
  final String patientId;
  final String patientName;
  final String reportedById;
  final String reportedByName;
  final String reaction;
  final String severity;
  final DateTime? startedAt;
  final String? notes;
  final bool isResolved;
  final DateTime createdAt;

  MedicationReactionModel({
    required this.id,
    required this.medicationId,
    required this.patientId,
    required this.patientName,
    required this.reportedById,
    required this.reportedByName,
    required this.reaction,
    required this.severity,
    this.startedAt,
    this.notes,
    required this.isResolved,
    required this.createdAt,
  });

  factory MedicationReactionModel.fromJson(Map<String, dynamic> json) {
    return MedicationReactionModel(
      id: json['id'] ?? '',
      medicationId: json['medication_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      reportedById: json['reported_by_id'] ?? '',
      reportedByName: json['reported_by_name'] ?? '',
      reaction: json['reaction'] ?? '',
      severity: json['severity'] ?? 'mild',
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      notes: json['notes'],
      isResolved: json['is_resolved'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'medication_id': medicationId,
    'reaction': reaction,
    'severity': severity,
    'started_at': startedAt?.toIso8601String(),
    'notes': notes,
  };
}
