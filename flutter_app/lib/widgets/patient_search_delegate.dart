import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/database_service.dart';
import '../../models/patient_model.dart';

class PatientSearchDelegate extends SearchDelegate<PatientModel?> {
  @override
  String get searchFieldLabel => 'Search patients...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Search by patient name'),
          ],
        ),
      );
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<PatientModel>>(
      future: DatabaseService().getAllPatients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final patients = (snapshot.data ?? []).where((p) {
          return p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.wardBedLabel.toLowerCase().contains(query.toLowerCase()) ||
              (p.diagnosisSummary?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();

        if (patients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No patients found for "$query"'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: patient.isCritical
                    ? AppTheme.criticalRed.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  color: patient.isCritical ? AppTheme.criticalRed : AppTheme.primaryColor,
                ),
              ),
              title: Text(patient.name),
              subtitle: Text(
                '${patient.wardBedLabel} • ${patient.status}',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              trailing: patient.isCritical
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.criticalRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CRITICAL',
                        style: TextStyle(
                          color: AppTheme.criticalRed,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () => close(context, patient),
            );
          },
        );
      },
    );
  }
}
