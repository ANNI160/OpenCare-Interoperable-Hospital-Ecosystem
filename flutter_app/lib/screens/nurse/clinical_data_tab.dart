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

class ClinicalDataTab extends StatefulWidget {
  final int wardNumber;
  final int bedNumber;

  const ClinicalDataTab({
    super.key,
    required this.wardNumber,
    required this.bedNumber,
  });

  @override
  State<ClinicalDataTab> createState() => _ClinicalDataTabState();
}

class _ClinicalDataTabState extends State<ClinicalDataTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PatientModel? _patient;
  List<VitalsModel> _vitals = [];
  List<MedicationModel> _medications = [];
  bool _isLoading = true;
  String _selectedVitalType = 'heartRate';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshData());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (_patient == null) return;
    try {
      final db = DatabaseService();
      final vitals = await db.getVitalsForPatient(_patient!.id);
      final meds = await db.getMedicationsForPatient(_patient!.id);
      if (mounted) {
        setState(() {
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
      _patient = await db.getPatientByWardBed(widget.wardNumber, widget.bedNumber);
      if (_patient != null) {
        _vitals = await db.getVitalsForPatient(_patient!.id);
        _medications = await db.getMedicationsForPatient(_patient!.id);
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_patient == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64,
                color: AppTheme.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No patient in Ward ${widget.wardNumber}, Bed ${widget.bedNumber}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Sub-tabs: Vitals | Medications
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.monitor_heart), text: 'Vitals'),
              Tab(icon: Icon(Icons.medication), text: 'Medications'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVitalsView(),
              _buildMedicationsView(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── VITALS VIEW ──────────────────────────────
  Widget _buildVitalsView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Latest vitals summary cards
            if (_vitals.isNotEmpty) ...[
              _buildLatestVitalsSummary(_vitals.first),
              const SizedBox(height: 20),
              // Vitals trend chart
              _buildVitalsChart(),
              const SizedBox(height: 20),
            ],

            // Record new vitals button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showRecordVitalsDialog,
                icon: const Icon(Icons.add),
                label: const Text('Record New Vitals'),
              ),
            ),

            const SizedBox(height: 20),

            // Vitals history
            Text('Vitals History',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._vitals.take(10).map((v) => _buildVitalsHistoryCard(v)),

            if (_vitals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.monitor_heart_outlined, size: 48,
                          color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      const Text('No vitals recorded yet'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestVitalsSummary(VitalsModel latest) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Latest Vitals',
                    style: Theme.of(context).textTheme.titleMedium),
                if (latest.hasAnyAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber,
                            size: 14, color: AppTheme.warningOrange),
                        SizedBox(width: 4),
                        Text('ALERTS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warningOrange)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _vitalChip('HR', '${latest.heartRate ?? '-'} bpm',
                    latest.isHeartRateAbnormal),
                _vitalChip('BP', latest.bloodPressure,
                    latest.isBPAbnormal),
                _vitalChip('SpO2', '${latest.oxygenSaturation ?? '-'}%',
                    latest.isOxygenLow),
                _vitalChip('Temp', '${latest.temperature ?? '-'}°C',
                    latest.isTemperatureAbnormal),
                _vitalChip('RR', '${latest.respiratoryRate ?? '-'}/min',
                    latest.isRespiratoryAbnormal),
                _vitalChip('Glucose', '${latest.glucoseLevel ?? '-'} mg/dL',
                    latest.isGlucoseAbnormal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalChip(String label, String value, bool isAbnormal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAbnormal
            ? AppTheme.criticalRed.withValues(alpha: 0.1)
            : AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAbnormal
              ? AppTheme.criticalRed.withValues(alpha: 0.3)
              : AppTheme.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isAbnormal ? AppTheme.criticalRed : AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAbnormal ? AppTheme.criticalRed : AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildVitalsChart() {
    if (_vitals.length < 2) return const SizedBox();

    final reversed = _vitals.reversed.toList();
    final data = reversed.take(10).toList();

    List<FlSpot> spots;
    String yLabel;
    Color lineColor;

    switch (_selectedVitalType) {
      case 'heartRate':
        spots = data
            .asMap()
            .entries
            .where((e) => e.value.heartRate != null)
            .map((e) => FlSpot(e.key.toDouble(), e.value.heartRate!.toDouble()))
            .toList();
        yLabel = 'Heart Rate (bpm)';
        lineColor = Colors.red;
        break;
      case 'oxygenSaturation':
        spots = data
            .asMap()
            .entries
            .where((e) => e.value.oxygenSaturation != null)
            .map((e) => FlSpot(e.key.toDouble(), e.value.oxygenSaturation!))
            .toList();
        yLabel = 'SpO2 (%)';
        lineColor = Colors.blue;
        break;
      case 'temperature':
        spots = data
            .asMap()
            .entries
            .where((e) => e.value.temperature != null)
            .map((e) => FlSpot(e.key.toDouble(), e.value.temperature!))
            .toList();
        yLabel = 'Temperature (°C)';
        lineColor = Colors.orange;
        break;
      default:
        spots = [];
        yLabel = '';
        lineColor = AppTheme.primaryColor;
    }

    if (spots.length < 2) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trend', style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<String>(
                  value: _selectedVitalType,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: 'heartRate', child: Text('Heart Rate')),
                    DropdownMenuItem(
                        value: 'oxygenSaturation', child: Text('SpO2')),
                    DropdownMenuItem(
                        value: 'temperature', child: Text('Temperature')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedVitalType = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withValues(alpha: 0.1),
                      ),
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

  Widget _buildVitalsHistoryCard(VitalsModel vital) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd().add_jm().format(vital.timestamp),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                Text(
                  'by ${vital.recordedByName}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (vital.heartRate != null)
                  _miniVitalChip('HR: ${vital.heartRate}', vital.isHeartRateAbnormal),
                if (vital.systolicBP != null)
                  _miniVitalChip('BP: ${vital.bloodPressure}', vital.isBPAbnormal),
                if (vital.oxygenSaturation != null)
                  _miniVitalChip('SpO2: ${vital.oxygenSaturation}%', vital.isOxygenLow),
                if (vital.temperature != null)
                  _miniVitalChip('Temp: ${vital.temperature}°C', vital.isTemperatureAbnormal),
                if (vital.respiratoryRate != null)
                  _miniVitalChip('RR: ${vital.respiratoryRate}', vital.isRespiratoryAbnormal),
              ],
            ),
            if (vital.notes != null && vital.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(vital.notes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniVitalChip(String text, bool isAbnormal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAbnormal ? AppTheme.criticalRed.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              color: isAbnormal ? AppTheme.criticalRed : AppTheme.textPrimary)),
    );
  }

  void _showRecordVitalsDialog() {
    final hrCtrl = TextEditingController();
    final sysCtrl = TextEditingController();
    final diaCtrl = TextEditingController();
    final spo2Ctrl = TextEditingController();
    final tempCtrl = TextEditingController();
    final rrCtrl = TextEditingController();
    final glucCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record Vitals',
                  style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _vitalsField(hrCtrl, 'Heart Rate', 'bpm')),
                const SizedBox(width: 12),
                Expanded(child: _vitalsField(spo2Ctrl, 'SpO2', '%')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _vitalsField(sysCtrl, 'Systolic BP', 'mmHg')),
                const SizedBox(width: 12),
                Expanded(child: _vitalsField(diaCtrl, 'Diastolic BP', 'mmHg')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _vitalsField(tempCtrl, 'Temperature', '°C')),
                const SizedBox(width: 12),
                Expanded(child: _vitalsField(rrCtrl, 'Resp Rate', '/min')),
              ]),
              const SizedBox(height: 12),
              _vitalsField(glucCtrl, 'Glucose', 'mg/dL'),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    final user = authProvider.currentUser;
                    if (user == null || _patient == null) return;

                    final vitals = VitalsModel(
                      id: '',
                      patientId: _patient!.id,
                      recordedById: user.id,
                      recordedByName: user.name,
                      timestamp: DateTime.now(),
                      heartRate: int.tryParse(hrCtrl.text),
                      systolicBP: int.tryParse(sysCtrl.text),
                      diastolicBP: int.tryParse(diaCtrl.text),
                      oxygenSaturation: double.tryParse(spo2Ctrl.text),
                      temperature: double.tryParse(tempCtrl.text),
                      respiratoryRate: int.tryParse(rrCtrl.text),
                      glucoseLevel: double.tryParse(glucCtrl.text),
                      notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                    );
                    try {
                      await DatabaseService().addVitals(vitals);
                      if (mounted) {
                        Navigator.pop(ctx);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vitals recorded'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'),
                              backgroundColor: AppTheme.errorColor),
                        );
                      }
                    }
                  },
                  child: const Text('Save Vitals'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vitalsField(TextEditingController ctrl, String label, String suffix) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
      ),
    );
  }

  // ─── MEDICATIONS VIEW ─────────────────────────
  Widget _buildMedicationsView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add medication button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddMedicationDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Medication'),
              ),
            ),
            const SizedBox(height: 16),

            if (_medications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.medication_outlined, size: 48,
                          color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      const Text('No medications prescribed yet'),
                    ],
                  ),
                ),
              )
            else
              ..._medications.map((med) => _buildMedicationCard(med)),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(MedicationModel med) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: med.isAdministered
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : med.isInjection
                        ? AppTheme.accentColor.withValues(alpha: 0.1)
                        : AppTheme.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                med.isInjection ? Icons.vaccines : Icons.medication,
                color: med.isAdministered
                    ? AppTheme.successColor
                    : med.isInjection
                        ? AppTheme.accentColor
                        : AppTheme.warningOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${med.dosage} • ${med.routeLabel}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('${med.frequencyLabel} • By Dr. ${med.prescribedByName}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (!med.isAdministered)
              ElevatedButton(
                onPressed: () => _administerMedication(med),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Give', style: TextStyle(fontSize: 12)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Given',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _administerMedication(MedicationModel med) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Administration'),
        content: Text('Administer ${med.name} ${med.dosage} to ${_patient?.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService().administerMedication(
          medicationId: med.id,
          nurseId: user.id,
          nurseName: user.name,
        );
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  void _showAddMedicationDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    String route = 'oral';
    String frequency = 'once';
    bool isInjection = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Medication',
                    style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Medication Name',
                      prefixIcon: Icon(Icons.medication)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Dosage (e.g. 500mg)',
                      prefixIcon: Icon(Icons.scale)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: route,
                  decoration: const InputDecoration(labelText: 'Route'),
                  items: const [
                    DropdownMenuItem(value: 'oral', child: Text('Oral')),
                    DropdownMenuItem(value: 'iv', child: Text('IV')),
                    DropdownMenuItem(value: 'im', child: Text('IM')),
                    DropdownMenuItem(value: 'sc', child: Text('SC')),
                    DropdownMenuItem(value: 'topical', child: Text('Topical')),
                  ],
                  onChanged: (v) {
                    setModalState(() {
                      route = v!;
                      isInjection = v == 'iv' || v == 'im' || v == 'sc';
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'once', child: Text('Once')),
                    DropdownMenuItem(value: 'bid', child: Text('Twice Daily')),
                    DropdownMenuItem(value: 'tid', child: Text('Three Times')),
                    DropdownMenuItem(value: 'qid', child: Text('Four Times')),
                    DropdownMenuItem(value: 'prn', child: Text('As Needed')),
                  ],
                  onChanged: (v) => setModalState(() => frequency = v!),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || dosageCtrl.text.isEmpty) return;
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final user = authProvider.currentUser;
                      if (user == null || _patient == null) return;

                      final med = MedicationModel(
                        id: '',
                        patientId: _patient!.id,
                        name: nameCtrl.text.trim(),
                        dosage: dosageCtrl.text.trim(),
                        route: route,
                        frequency: frequency,
                        isInjection: isInjection,
                        prescribedById: user.id,
                        prescribedByName: user.name,
                        createdAt: DateTime.now(),
                      );
                      await DatabaseService().addMedication(med);
                      if (mounted) {
                        Navigator.pop(ctx);
                        _loadData();
                      }
                    },
                    child: const Text('Add Medication'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
