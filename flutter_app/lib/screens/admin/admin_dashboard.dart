import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/patient_model.dart';
import '../../models/user_model.dart';
import '../settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PatientModel> _patients = [];
  List<UserModel> _staff = [];
  int _totalWards = 5;
  int _bedsPerWard = 10;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final config = await db.getHospitalConfig();

      _totalWards = config['total_wards'] ?? 5;
      _bedsPerWard = config['beds_per_ward'] ?? 10;
      _patients = await db.getAllPatients();
      
      final doctors = await authProvider.getAllDoctors();
      final nurses = await authProvider.getAllNurses();
      _staff = [...doctors, ...nurses];

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
        content: const Text('Are you sure?'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 36, width: 120,
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
            const SizedBox(width: 8),
            const Text('Admin'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.grid_view), text: 'Bed Map'),
            Tab(icon: Icon(Icons.people), text: 'Staff'),
            Tab(icon: Icon(Icons.history), text: 'Audit'),
            Tab(icon: Icon(Icons.settings), text: 'Config'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildBedMapTab(),
                _buildStaffTab(),
                _buildAuditTab(),
                _buildConfigTab(),
              ],
            ),
    );
  }

  // ─── OVERVIEW TAB ─────────────────────────────
  Widget _buildOverviewTab() {
    final totalBeds = _totalWards * _bedsPerWard;
    final occupiedBeds = _patients.length;
    final criticalPatients = _patients.where((p) => p.isCritical).length;
    final totalDoctors = _staff.where((s) => s.role == 'doctor').length;
    final totalNurses = _staff.where((s) => s.role == 'nurse').length;
    final occupancyRate = totalBeds > 0 ? (occupiedBeds / totalBeds * 100) : 0.0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _statCard('Total Patients', '$occupiedBeds', Icons.people, AppTheme.primaryColor),
                _statCard('Occupancy', '${occupancyRate.toStringAsFixed(0)}%', Icons.bed, AppTheme.accentColor),
                _statCard('Critical', '$criticalPatients', Icons.warning_amber, AppTheme.criticalRed),
                _statCard('Available Beds', '${totalBeds - occupiedBeds}', Icons.hotel, AppTheme.successColor),
                _statCard('Doctors', '$totalDoctors', Icons.local_hospital, Colors.purple),
                _statCard('Nurses', '$totalNurses', Icons.medical_services, Colors.teal),
              ],
            ),

            const SizedBox(height: 24),

            // Recent admissions
            Text('Recent Admissions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._patients.take(5).map((p) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: p.isCritical
                          ? AppTheme.criticalRed.withValues(alpha: 0.2)
                          : AppTheme.primaryColor.withValues(alpha: 0.2),
                      child: Icon(Icons.person,
                          color: p.isCritical ? AppTheme.criticalRed : AppTheme.primaryColor),
                    ),
                    title: Text(p.name),
                    subtitle: Text('${p.wardBedLabel} • ${p.status}'),
                    trailing: Text(
                      DateFormat.MMMd().format(p.admissionDate),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Text(value,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ─── BED MAP TAB ──────────────────────────────
  Widget _buildBedMapTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_totalWards, (wardIndex) {
            final wardNum = wardIndex + 1;
            final wardPatients = _patients.where((p) => p.wardNumber == wardNum).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Ward $wardNum', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${wardPatients.length}/$_bedsPerWard',
                          style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_bedsPerWard, (bedIndex) {
                    final bedNum = bedIndex + 1;
                    final patient = wardPatients.where((p) => p.bedNumber == bedNum).firstOrNull;
                    final isOccupied = patient != null;
                    final isCritical = patient?.isCritical ?? false;

                    return Tooltip(
                      message: isOccupied ? '${patient!.name} (${patient.status})' : 'Empty',
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCritical
                              ? AppTheme.criticalRed.withValues(alpha: 0.2)
                              : isOccupied
                                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCritical
                                ? AppTheme.criticalRed
                                : isOccupied
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$bedNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCritical
                                  ? AppTheme.criticalRed
                                  : isOccupied
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ─── STAFF TAB ────────────────────────────────
  Widget _buildStaffTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _staff.isEmpty
          ? const Center(child: Text('No staff registered'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _staff.length,
              itemBuilder: (ctx, i) {
                final member = _staff[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: member.role == 'doctor'
                          ? Colors.purple.withValues(alpha: 0.2)
                          : Colors.teal.withValues(alpha: 0.2),
                      child: Icon(
                        member.role == 'doctor' ? Icons.local_hospital : Icons.medical_services,
                        color: member.role == 'doctor' ? Colors.purple : Colors.teal,
                      ),
                    ),
                    title: Text(member.name),
                    subtitle: Text(
                      '${member.role.toUpperCase()} • ${member.employeeId}'
                      '${member.specialization != null ? ' • ${member.specialization}' : ''}'
                      '${member.assignedWard != null ? ' • Ward ${member.assignedWard}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: member.isOnline ? AppTheme.successColor : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'delete', child: Text('Remove')),
                          ],
                          onSelected: (val) async {
                            if (val == 'delete') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Remove Staff'),
                                  content: Text('Remove ${member.name}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await DatabaseService().deleteUser(member.id);
                                _loadData();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ─── AUDIT TAB ─────────────────────────────
  Widget _buildAuditTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService().getAuditLogs(limit: 200),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const Center(child: Text('No audit logs yet'));
        }
        return RefreshIndicator(
          onRefresh: () async { setState(() {}); },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (ctx, i) {
              final log = logs[i];
              final action = (log['action'] ?? '').toString();
              final entity = (log['entity_type'] ?? '').toString();
              final ts = DateTime.tryParse(log['timestamp'] ?? '');
              final meta = log['metadata_'] as Map<String, dynamic>?;
              final icon = _auditIcon(action);
              final color = _auditColor(action);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(
                    action.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$entity${meta != null && meta['name'] != null ? ' — ${meta['name']}' : ''}',
                          style: const TextStyle(fontSize: 12)),
                      if (ts != null)
                        Text(DateFormat('MMM d, h:mm a').format(ts),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _auditIcon(String action) {
    if (action.contains('emergency')) return Icons.emergency;
    if (action.contains('patient')) return Icons.person;
    if (action.contains('vitals')) return Icons.monitor_heart;
    if (action.contains('medication') || action.contains('prescribe') || action.contains('administer')) return Icons.medication;
    return Icons.history;
  }

  Color _auditColor(String action) {
    if (action.contains('emergency')) return AppTheme.criticalRed;
    if (action.contains('create')) return AppTheme.accentColor;
    if (action.contains('update') || action.contains('administer')) return AppTheme.warningOrange;
    if (action.contains('resolve')) return AppTheme.successColor;
    return AppTheme.primaryColor;
  }

  // ─── CONFIG TAB ───────────────────────────────
  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hospital Configuration', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _configRow('Total Wards', _totalWards, (val) {
                    setState(() => _totalWards = val);
                  }),
                  const Divider(),
                  _configRow('Beds per Ward', _bedsPerWard, (val) {
                    setState(() => _bedsPerWard = val);
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await DatabaseService().updateHospitalConfig(
                    totalWards: _totalWards,
                    bedsPerWard: _bedsPerWard,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Configuration saved'),
                        backgroundColor: AppTheme.successColor,
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
              },
              child: const Text('Save Configuration'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
            Text('$value',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}
