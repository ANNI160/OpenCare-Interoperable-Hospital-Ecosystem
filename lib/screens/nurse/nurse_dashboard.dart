import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/logo_widget.dart';
import 'patient_details_tab.dart';
import '../../widgets/patient_search_delegate.dart';
import 'clinical_data_tab.dart';
import 'communication_hub_tab.dart';
import 'tasks_tab.dart';
import '../settings_screen.dart';
import '../../services/database_service.dart';

class NurseDashboard extends StatefulWidget {
  const NurseDashboard({super.key});

  @override
  State<NurseDashboard> createState() => _NurseDashboardState();
}

class _NurseDashboardState extends State<NurseDashboard> {
  int _currentIndex = 0;
  int _selectedWard = 1;
  int _selectedBed = 1;
  int _refreshKey = 0; // Used to force rebuild of tabs

  @override
  void initState() {
    super.initState();
  }

  List<Widget> _buildTabs() {
    return [
      PatientDetailsTab(
        key: ValueKey('patient_${_selectedWard}_${_selectedBed}_$_refreshKey'),
        wardNumber: _selectedWard,
        bedNumber: _selectedBed,
      ),
      ClinicalDataTab(
        key: ValueKey('clinical_${_selectedWard}_${_selectedBed}_$_refreshKey'),
        wardNumber: _selectedWard,
        bedNumber: _selectedBed,
      ),
      CommunicationHubTab(
        key: ValueKey('comm_${_selectedWard}_${_selectedBed}_$_refreshKey'),
        wardNumber: _selectedWard,
        bedNumber: _selectedBed,
      ),
      TasksTab(
        wardNumber: _selectedWard,
      ),
    ];
  }

  void _refreshTabs() {
    setState(() {
      _refreshKey++;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  void _showWardBedSelector() {
    final databaseService = DatabaseService();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FutureBuilder<Map<String, dynamic>?>(
        future: databaseService.getHospitalConfig(),
        builder: (context, configSnapshot) {
          final totalWards = configSnapshot.data?['total_wards'] ?? 10;
          final bedsPerWard = configSnapshot.data?['beds_per_ward'] ?? 20;
          
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Ward & Bed',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    
                    // Ward selector
                    Text(
                      'Ward Number',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(totalWards, (index) {
                        final ward = index + 1;
                        final isSelected = _selectedWard == ward;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _selectedWard = ward;
                            });
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$ward',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Bed selector
                    Text(
                      'Bed Number',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(bedsPerWard, (index) {
                        final bed = index + 1;
                        final isSelected = _selectedBed == bed;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _selectedBed = bed;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accentColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$bed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _refreshTabs();
                        },
                        child: const Text(
                          'Confirm Selection',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
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
                  Icon(
                    Icons.favorite,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
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
              showSearch(
                context: context,
                delegate: PatientSearchDelegate(),
              );
            },
            tooltip: 'Search Patient',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Ward & Bed selector header
          GestureDetector(
            onTap: _showWardBedSelector,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [AppTheme.cardShadow],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Nurse',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Ward $_selectedWard',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Bed $_selectedBed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _buildTabs(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refresh tabs to pick up any new patient data
          _refreshTabs();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Patient',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_information_outlined),
            selectedIcon: Icon(Icons.medical_information),
            label: 'Clinical',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}
