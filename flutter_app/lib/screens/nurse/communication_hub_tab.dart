import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/message_model.dart';
import '../../models/patient_model.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';

class CommunicationHubTab extends StatefulWidget {
  final int wardNumber;
  final int bedNumber;

  const CommunicationHubTab({
    super.key,
    required this.wardNumber,
    required this.bedNumber,
  });

  @override
  State<CommunicationHubTab> createState() => _CommunicationHubTabState();
}

class _CommunicationHubTabState extends State<CommunicationHubTab> {
  PatientModel? _patient;
  List<MessageModel> _messages = [];
  List<UserModel> _doctors = [];
  bool _isLoading = true;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pollMessages() async {
    if (_patient == null) return;
    try {
      final db = DatabaseService();
      final messages = await db.getMessagesForPatient(_patient!.id);
      if (mounted && messages.length != _messages.length) {
        setState(() => _messages = messages);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      _patient = await db.getPatientByWardBed(widget.wardNumber, widget.bedNumber);
      _doctors = await authProvider.getAllDoctors();
      
      if (_patient != null) {
        _messages = await db.getMessagesForPatient(_patient!.id);
        // Auto-select attending doctor
        if (_patient!.attendingDoctorId != null) {
          _selectedDoctorId = _patient!.attendingDoctorId;
          _selectedDoctorName = _patient!.attendingDoctorName;
        }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _patient == null) return;
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor to message')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final db = DatabaseService();
    final message = MessageModel(
      id: '',
      senderId: user.id,
      senderName: user.name,
      senderRole: user.role,
      receiverId: _selectedDoctorId!,
      receiverName: _selectedDoctorName ?? 'Doctor',
      patientId: _patient!.id,
      patientName: _patient!.name,
      content: _messageController.text.trim(),
      type: 'text',
      sentAt: DateTime.now(),
    );

    try {
      await db.sendMessage(message);
      _messageController.clear();
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
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
            Icon(Icons.person_off_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No patient in Ward ${widget.wardNumber}, Bed ${widget.bedNumber}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text('Register a patient first to start messaging'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Patient & Doctor header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [AppTheme.cardShadow],
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Re: ${_patient!.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _selectedDoctorId,
                      hint: const Text('Select Doctor'),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _doctors.map((doc) {
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text('Dr. ${doc.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDoctorId = val;
                          _selectedDoctorName = _doctors.firstWhere((d) => d.id == val).name;
                        });
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_outlined, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      const Text('No messages yet'),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final isMe = msg.senderId == authProvider.currentUser?.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(4) : null,
                            bottomLeft: !isMe ? const Radius.circular(4) : null,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.senderName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isMe ? Colors.white70 : AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.jm().format(msg.sentAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white54 : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
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
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
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
}
