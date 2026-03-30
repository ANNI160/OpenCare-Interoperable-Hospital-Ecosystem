class PatientModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? diagnosisSummary;
  final int wardNumber;
  final int bedNumber;
  final DateTime admissionDate;
  final String? attendingDoctorId;
  final String? attendingDoctorName;
  final List<String> allergies;
  final String? specialNotes;
  final bool isCritical;
  final String status;
  final String? assignedNurseId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.diagnosisSummary,
    required this.wardNumber,
    required this.bedNumber,
    required this.admissionDate,
    this.attendingDoctorId,
    this.attendingDoctorName,
    this.allergies = const [],
    this.specialNotes,
    this.isCritical = false,
    this.status = 'stable',
    this.assignedNurseId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get wardBedLabel => 'Ward $wardNumber - Bed $bedNumber';
  bool get hasAllergies => allergies.isNotEmpty;

  PatientModel copyWith({
    String? name, int? age, String? gender, String? diagnosisSummary,
    int? wardNumber, int? bedNumber, String? attendingDoctorId,
    String? attendingDoctorName, List<String>? allergies,
    String? specialNotes, bool? isCritical, String? status,
    String? assignedNurseId,
  }) {
    return PatientModel(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      diagnosisSummary: diagnosisSummary ?? this.diagnosisSummary,
      wardNumber: wardNumber ?? this.wardNumber,
      bedNumber: bedNumber ?? this.bedNumber,
      admissionDate: admissionDate,
      attendingDoctorId: attendingDoctorId ?? this.attendingDoctorId,
      attendingDoctorName: attendingDoctorName ?? this.attendingDoctorName,
      allergies: allergies ?? this.allergies,
      specialNotes: specialNotes ?? this.specialNotes,
      isCritical: isCritical ?? this.isCritical,
      status: status ?? this.status,
      assignedNurseId: assignedNurseId ?? this.assignedNurseId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      diagnosisSummary: json['diagnosis_summary'],
      wardNumber: json['ward_number'] ?? 0,
      bedNumber: json['bed_number'] ?? 0,
      admissionDate: DateTime.parse(json['admission_date'] ?? DateTime.now().toIso8601String()),
      attendingDoctorId: json['attending_doctor_id'],
      attendingDoctorName: json['attending_doctor_name'],
      allergies: (json['allergies'] as List<dynamic>?)?.cast<String>() ?? [],
      specialNotes: json['special_notes'],
      isCritical: json['is_critical'] ?? false,
      status: json['status'] ?? 'stable',
      assignedNurseId: json['assigned_nurse_id'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'diagnosis_summary': diagnosisSummary,
    'ward_number': wardNumber,
    'bed_number': bedNumber,
    'attending_doctor_id': attendingDoctorId,
    'attending_doctor_name': attendingDoctorName,
    'allergies': allergies,
    'special_notes': specialNotes,
    'is_critical': isCritical,
    'status': status,
    'assigned_nurse_id': assignedNurseId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientModel &&
          id == other.id &&
          name == other.name &&
          wardNumber == other.wardNumber &&
          bedNumber == other.bedNumber;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ wardNumber.hashCode ^ bedNumber.hashCode;
}
