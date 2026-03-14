class TaskModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;
  final String? patientId;
  final String? patientName;
  final String assignedNurseId;
  final String assignedNurseName;
  final int wardNumber;
  final DateTime createdAt;
  final String? completedByNurseId;
  final String? completedByNurseName;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.patientId,
    this.patientName,
    required this.assignedNurseId,
    required this.assignedNurseName,
    required this.wardNumber,
    required this.createdAt,
    this.completedByNurseId,
    this.completedByNurseName,
    this.completedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      isCompleted: json['is_completed'] ?? false,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      patientId: json['patient_id'],
      patientName: json['patient_name'],
      assignedNurseId: json['assigned_nurse_id'] ?? '',
      assignedNurseName: json['assigned_nurse_name'] ?? '',
      wardNumber: json['ward_number'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      completedByNurseId: json['completed_by_nurse_id'],
      completedByNurseName: json['completed_by_nurse_name'],
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'due_date': dueDate?.toIso8601String(),
    'patient_id': patientId,
    'patient_name': patientName,
    'ward_number': wardNumber,
  };
}
