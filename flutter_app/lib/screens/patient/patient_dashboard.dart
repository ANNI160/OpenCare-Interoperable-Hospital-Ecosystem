import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../models/appointment_model.dart';
import '../../models/medication_model.dart';
import '../../models/medication_reaction_model.dart';
import '../../models/message_model.dart';
import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();

  PatientModel? _patient;
  List<AppointmentModel> _appointments = [];
  List<MedicationModel> _medications = [];
  List<MedicationReactionModel> _reactions = [];
  List<MessageModel> _messages = [];

  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _loadData(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);

    try {
      final db = DatabaseService();
      final patient = await db.getMyPatientProfile();
      final appointments = await db.getMyPortalAppointments();
      final medications = await db.getMyPortalMedications();
      final reactions = await db.getMyMedicationReactions();
      final messages = await db.getMyPortalMessages();

      if (!mounted) return;
      setState(() {
        _patient = patient;
        _appointments = appointments;
        _medications = medications;
        _reactions = reactions;
        _messages = messages;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Portal${_patient != null ? ' - ${_patient!.name}' : ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.event_available), text: 'Appointments'),
            Tab(icon: Icon(Icons.chat), text: 'Doctor Chat'),
            Tab(icon: Icon(Icons.medication), text: 'Medicines'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsTab(),
                _buildMessagesTab(),
                _buildMedicationsTab(),
              ],
            ),
    );
  }

  Widget _buildAppointmentsTab() {
    if (_appointments.isEmpty) {
      return const Center(child: Text('No appointments scheduled yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appt = _appointments[index];
          final dt = DateFormat('dd MMM yyyy, hh:mm a').format(appt.appointmentTime);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
              title: Text(dt),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doctor: ${appt.doctorName}'),
                  if ((appt.reason ?? '').isNotEmpty) Text('Reason: ${appt.reason}'),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(appt.status.toUpperCase(), style: const TextStyle(fontSize: 11)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesTab() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('No messages yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg.senderId == currentUser?.id;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [AppTheme.cardShadow],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.senderName,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.content,
                              style: TextStyle(color: isMe ? Colors.white : AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(msg.sentAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white60 : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message to your doctor',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendPortalMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationsTab() {
    if (_medications.isEmpty) {
      return const Center(child: Text('No medication records available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._medications.map((med) {
            final relatedReactions = _reactions
                .where((r) => r.medicationId == med.id)
                .toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(med.isInjection ? Icons.vaccines : Icons.medication,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            med.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Dosage: ${med.dosage}'),
                    Text('Route: ${med.routeLabel}'),
                    Text('Frequency: ${med.frequencyLabel}'),
                    Text('Start date: ${DateFormat('dd MMM yyyy').format(med.createdAt)}'),
                    if ((med.notes ?? '').isNotEmpty) Text('Note: ${med.notes}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: relatedReactions.isEmpty
                          ? [
                              const Text(
                                'No reactions reported.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ]
                          : relatedReactions.map((r) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${r.severity.toUpperCase()}: ${r.reaction}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.report_problem_outlined),
                        label: const Text('Report Reaction'),
                        onPressed: () => _showReportReactionDialog(med),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _sendPortalMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      final db = DatabaseService();
      await db.sendPortalMessage(content: content);
      _messageController.clear();
      await _loadData(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _showReportReactionDialog(MedicationModel med) async {
    final reactionController = TextEditingController();
    final notesController = TextEditingController();
    String severity = 'mild';

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Reaction for ${med.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reactionController,
                  decoration: const InputDecoration(labelText: 'What reaction are you feeling?'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: severity,
                  items: const [
                    DropdownMenuItem(value: 'mild', child: Text('Mild')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'severe', child: Text('Severe')),
                  ],
                  onChanged: (v) => setStateDialog(() => severity = v ?? 'mild'),
                  decoration: const InputDecoration(labelText: 'Severity'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Additional notes (optional)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (reactionController.text.trim().isEmpty) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );

    if (shouldSubmit != true) return;

    try {
      final db = DatabaseService();
      await db.reportMedicationReaction(
        MedicationReactionModel(
          id: '',
          medicationId: med.id,
          patientId: '',
          patientName: '',
          reportedById: '',
          reportedByName: '',
          reaction: reactionController.text.trim(),
          severity: severity,
          startedAt: DateTime.now(),
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
          isResolved: false,
          createdAt: DateTime.now(),
        ),
      );
      await _loadData(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report reaction: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }
}
