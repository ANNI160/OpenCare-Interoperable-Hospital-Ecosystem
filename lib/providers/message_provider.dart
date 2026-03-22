import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';

class MessageProvider extends ChangeNotifier {
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  Future<void> sendMessage(DatabaseService db, MessageModel message) async {
    try {
      await db.sendMessage(message);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(DatabaseService db, String messageId) async {
    try {
      await db.markMessageAsRead(messageId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount(DatabaseService db, String userId) async {
    try {
      _unreadCount = await db.getUnreadMessageCount(userId);
      notifyListeners();
    } catch (e) {
      // Silent fail
    }
  }
}
