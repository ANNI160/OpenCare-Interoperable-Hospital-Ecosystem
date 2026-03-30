import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/patient_model.dart';
import '../../models/vitals_model.dart';
import '../../models/medication_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../utils/tts_helper.dart';

class PatientDetailView extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailView({super.key, required this.patient});

  @override
  State<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<PatientDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VitalsModel> _vitals = [];
  List<MedicationModel> _medications = [];
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  final _messageController = TextEditingController();
  List<UserModel> _nurses = [];

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollUpdates());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pollUpdates() async {
    try {
      final db = DatabaseService();
      final messages = await db.getMessagesForPatient(widget.patient.id);
      final vitals = await db.getVitalsForPatient(widget.patient.id);
      final meds = await db.getMedicationsForPatient(widget.patient.id);
      if (mounted) {
        setState(() {
          _messages = messages;
          _vitals = vitals;
          _medications = meds;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      _vitals = await db.getVitalsForPatient(widget.patient.id);
      _medications = await db.getMedicationsForPatient(widget.patient.id);
      _messages = await db.getMessagesForPatient(widget.patient.id);
      _nurses = await authProvider.getAllNurses();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.patient.isCritical
        ? AppTheme.criticalRed
        : widget.patient.status == 'pending'
            ? AppTheme.warningOrange
            : AppTheme.stableGreen;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available),
            onPressed: _showCreateAppointmentDialog,
            tooltip: 'Schedule Appointment',
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: _speakSummary,
            tooltip: 'Voice Summary',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_heart), text: 'Vitals'),
            Tab(icon: Icon(Icons.medication), text: 'Meds'),
            Tab(icon: Icon(Icons.chat), text: 'Messages'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Patient info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [AppTheme.cardShadow],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.patient.age}y ${widget.patient.gender} • ${widget.patient.wardBedLabel}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (widget.patient.diagnosisSummary != null)
                        Text(
                          widget.patient.diagnosisSummary!,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.patient.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVitalsTab(),
                      _buildMedicationsTab(),
                      _buildMessagesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─── VITALS TAB ────────────────────────────────
  Widget _buildVitalsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_vitals.isNotEmpty) ...[
              _buildLatestVitalsCard(_vitals.first),
              const SizedBox(height: 16),
              if (_vitals.length >= 2) _buildVitalsChart(),
              const SizedBox(height: 16),
            ],
            ..._vitals.take(10).map((v) => _buildVitalRow(v)),
            if (_vitals.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.monitor_heart_outlined, size: 48,
                        color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    const Text('No vitals recorded'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestVitalsCard(VitalsModel v) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Latest Vitals', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                if (v.hasAnyAlert)
                  const Icon(Icons.warning_amber, color: AppTheme.warningOrange, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _vitalBadge('HR', '${v.heartRate ?? '-'}', 'bpm', v.isHeartRateAbnormal),
                _vitalBadge('BP', v.bloodPressure, 'mmHg', v.isBPAbnormal),
                _vitalBadge('SpO2', '${v.oxygenSaturation ?? '-'}', '%', v.isOxygenLow),
                _vitalBadge('Temp', '${v.temperature ?? '-'}', '°C', v.isTemperatureAbnormal),
                _vitalBadge('RR', '${v.respiratoryRate ?? '-'}', '/min', v.isRespiratoryAbnormal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalBadge(String label, String value, String unit, bool isAbnormal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAbnormal
            ? AppTheme.criticalRed.withValues(alpha: 0.1)
            : AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: isAbnormal ? AppTheme.criticalRed : AppTheme.textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isAbnormal ? AppTheme.criticalRed : AppTheme.textPrimary)),
          Text(unit, style: TextStyle(fontSize: 9, color: isAbnormal ? AppTheme.criticalRed : AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildVitalsChart() {
    final reversed = _vitals.reversed.take(10).toList();
    final spots = reversed
        .asMap()
        .entries
        .where((e) => e.value.heartRate != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.heartRate!.toDouble()))
        .toList();

    if (spots.length < 2) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Heart Rate Trend', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalRow(VitalsModel v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Text(DateFormat.jm().format(v.timestamp),
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 6,
                children: [
                  if (v.heartRate != null) Text('HR:${v.heartRate}', style: TextStyle(fontSize: 11, color: v.isHeartRateAbnormal ? AppTheme.criticalRed : AppTheme.textPrimary)),
                  if (v.systolicBP != null) Text('BP:${v.bloodPressure}', style: TextStyle(fontSize: 11, color: v.isBPAbnormal ? AppTheme.criticalRed : AppTheme.textPrimary)),
                  if (v.oxygenSaturation != null) Text('SpO2:${v.oxygenSaturation}%', style: TextStyle(fontSize: 11, color: v.isOxygenLow ? AppTheme.criticalRed : AppTheme.textPrimary)),
                  if (v.temperature != null) Text('T:${v.temperature}°C', style: TextStyle(fontSize: 11, color: v.isTemperatureAbnormal ? AppTheme.criticalRed : AppTheme.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MEDICATIONS TAB ──────────────────────────
  Widget _buildMedicationsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _medications.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.medication_outlined, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                const Text('No medications'),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _medications.length,
              itemBuilder: (ctx, i) {
                final med = _medications[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      med.isInjection ? Icons.vaccines : Icons.medication,
                      color: med.isAdministered ? AppTheme.successColor : AppTheme.warningOrange,
                    ),
                    title: Text(med.name),
                    subtitle: Text('${med.dosage} • ${med.routeLabel} • ${med.frequencyLabel}'),
                    trailing: med.isAdministered
                        ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                        : const Icon(Icons.pending, color: AppTheme.warningOrange),
                  ),
                );
              },
            ),
    );
  }

  // ─── MESSAGES TAB ─────────────────────────────
  Widget _buildMessagesTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chat_outlined, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    const Text('No messages'),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = _messages[i];
                    final isMe = msg.senderId == user?.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg.senderName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isMe ? Colors.white70 : AppTheme.primaryColor)),
                            const SizedBox(height: 4),
                            Text(msg.content, style: TextStyle(color: isMe ? Colors.white : AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text(DateFormat.jm().format(msg.sentAt), style: TextStyle(fontSize: 10, color: isMe ? Colors.white54 : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Message nurse...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    // Send to the first nurse (or assigned nurse)
    final targetNurse = _nurses.isNotEmpty ? _nurses.first : null;
    if (targetNurse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No nurses available')),
      );
      return;
    }

    final db = DatabaseService();
    final msg = MessageModel(
      id: '',
      senderId: user.id,
      senderName: user.name,
      senderRole: user.role,
      receiverId: targetNurse.id,
      receiverName: targetNurse.name,
      patientId: widget.patient.id,
      patientName: widget.patient.name,
      content: _messageController.text.trim(),
      type: 'text',
      sentAt: DateTime.now(),
    );

    try {
      await db.sendMessage(msg);
      _messageController.clear();
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _showCreateAppointmentDialog() async {
    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate);
          final formattedTime = selectedTime.format(context);

          return AlertDialog(
            title: const Text('Schedule Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(formattedDate),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(formattedTime),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                ),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Schedule'),
              ),
            ],
          );
        },
      ),
    );

    if (shouldSubmit != true) return;

    final appointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    try {
      final db = DatabaseService();
      final appointment = AppointmentModel(
        id: '',
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        doctorId: '',
        doctorName: '',
        appointmentTime: appointmentDateTime,
        reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
        status: 'scheduled',
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.createAppointment(appointment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment scheduled successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule appointment: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  void _speakSummary() {
    final p = widget.patient;
    final latestVitals = _vitals.isNotEmpty ? _vitals.first : null;

    String summary = 'Patient ${p.name}, ${p.age} years old ${p.gender}, '
        'admitted in Ward ${p.wardNumber} Bed ${p.bedNumber}. '
        'Status: ${p.status}. ';

    if (p.diagnosisSummary != null) {
      summary += 'Diagnosis: ${p.diagnosisSummary}. ';
    }

    if (latestVitals != null) {
      summary += 'Latest vitals: ';
      if (latestVitals.heartRate != null) summary += 'Heart rate ${latestVitals.heartRate} bpm. ';
      if (latestVitals.systolicBP != null) summary += 'Blood pressure ${latestVitals.bloodPressure}. ';
      if (latestVitals.oxygenSaturation != null) summary += 'Oxygen ${latestVitals.oxygenSaturation} percent. ';
      if (latestVitals.temperature != null) summary += 'Temperature ${latestVitals.temperature} degrees. ';
    }

    summary += '${_medications.length} medications prescribed. ';
    summary += '${_messages.length} messages in thread.';

    TtsHelper.speak(summary);
  }
}
