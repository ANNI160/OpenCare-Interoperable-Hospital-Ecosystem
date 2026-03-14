import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/patient_model.dart';
import '../../models/vitals_model.dart';
import '../../widgets/patient_search_delegate.dart';
import '../settings_screen.dart';
import 'patient_detail_view.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PatientModel> _patients = [];
  List<Map<String, dynamic>> _activeEmergencies = [];
  bool _isLoading = true;
  int _totalWards = 5;
  Timer? _emergencyPollTimer;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _pollEmergencies();
    _emergencyPollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pollEmergencies(),
    );
  }

  Future<void> _pollEmergencies() async {
    try {
      final db = DatabaseService();
      final emergencies = await db.getActiveEmergencies();
      if (mounted) setState(() => _activeEmergencies = emergencies);
    } catch (_) {}
  }

  Future<void> _loadConfig() async {
    try {
      final db = DatabaseService();
      final config = await db.getHospitalConfig();
      if (mounted) {
        setState(() {
          _totalWards = config['total_wards'] ?? 5;
          _tabController = TabController(length: _totalWards, vsync: this);
          _tabController.addListener(_onTabChanged);
        });
        _loadPatients();
      }
    } catch (e) {
      setState(() {
        _totalWards = 5;
        _tabController = TabController(length: _totalWards, vsync: this);
        _tabController.addListener(_onTabChanged);
        _isLoading = false;
      });
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final wardNumber = _tabController.index + 1;
      _patients = await db.getPatientsByWard(wardNumber);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _emergencyPollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 36,
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 20, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: PatientSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: List.generate(_totalWards, (i) => Tab(text: 'Ward ${i + 1}')),
        ),
      ),
      body: Column(
        children: [
          // ─── Emergency Alert Banner ───────────────
          if (_activeEmergencies.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppTheme.criticalRed,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: _activeEmergencies.map((em) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${em['reason'] ?? 'Emergency'} — ${em['patient_name']} '
                            '(Ward ${em['ward_number']}, Bed ${em['bed_number']})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (em['status'] == 'active')
                          TextButton(
                            onPressed: () => _acknowledgeEmergency(em),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white24,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('ACK', style: TextStyle(fontSize: 12)),
                          ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () => _resolveEmergency(em),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white24,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('RESOLVE', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          // ─── Main Content ─────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadPatients,
                    child: _patients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bed_outlined, size: 64,
                                    color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text('No patients in Ward ${_tabController.index + 1}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.textSecondary)),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                      ),
                      itemCount: _patients.length,
                      itemBuilder: (ctx, i) => _BedCard(
                        patient: _patients[i],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientDetailView(
                                patient: _patients[i],
                              ),
                            ),
                          ).then((_) => _loadPatients());
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeEmergency(Map<String, dynamic> em) async {
    try {
      await DatabaseService().acknowledgeEmergency(em['id']);
      _pollEmergencies();
    } catch (_) {}
  }

  Future<void> _resolveEmergency(Map<String, dynamic> em) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Emergency'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Resolution notes (optional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await DatabaseService().resolveEmergency(
          em['id'],
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        );
        _pollEmergencies();
      } catch (_) {}
    }
    notesController.dispose();
  }
}

class _BedCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;

  const _BedCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = patient.isCritical
        ? AppTheme.criticalRed
        : patient.status == 'pending'
            ? AppTheme.warningOrange
            : AppTheme.stableGreen;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              top: BorderSide(color: statusColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bed number badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Bed ${patient.bedNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Patient name
              Text(
                patient.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Age & Gender
              Text(
                '${patient.age}y • ${patient.gender}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),

              const SizedBox(height: 8),

              // Diagnosis
              if (patient.diagnosisSummary != null && patient.diagnosisSummary!.isNotEmpty)
                Text(
                  patient.diagnosisSummary!,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const Spacer(),

              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  patient.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
