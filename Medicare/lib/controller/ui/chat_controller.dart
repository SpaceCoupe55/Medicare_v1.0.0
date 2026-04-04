import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/helpers/utils/generator.dart';
import 'package:medicare/model/chat_model.dart' as legacy;
import 'package:medicare/views/my_controller.dart';

/// Bridges Firestore real-time chat with the existing UI.
/// The UI still reads [chat], [selectChat], [searchChat] using the legacy
/// ChatModel types — we keep those types but populate from Firestore streams.
class ChatController extends MyController {
  List<legacy.ChatModel> chat = [];
  List<legacy.ChatModel> searchChat = [];
  legacy.ChatModel? selectChat;

  SearchController searchController = SearchController();
  TextEditingController messageController = TextEditingController();
  ScrollController? scrollController;

  late Timer _timer;
  int _nowTime = 0;
  String timeText = "00 : 00";
  int selectedChat = 0;

  String get _currentUserId => AppAuthController.instance.user?.uid ?? '';

  // Firestore
  StreamSubscription? _roomsSub;
  final Map<String, StreamSubscription> _messageSubs = {};
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ChatController() {
    scrollController = ScrollController();
    startTimer();
    _subscribeToRooms();
  }

  // ── Firestore subscriptions ──────────────────────────────────────────────

  void _subscribeToRooms() {
    _roomsSub = _db
        .collection('chats')
        .where('participants', arrayContains: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      chat = snap.docs.map(_roomToLegacyModel).toList();
      searchChat = List.from(chat);
      if (chat.isNotEmpty && selectChat == null) {
        selectChat = chat.first;
        _subscribeToMessages(chat.first.id.toString());
      }
      update();
    });
  }

  void _subscribeToMessages(String roomId) {
    _messageSubs[roomId]?.cancel();
    _messageSubs[roomId] = _db
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snap) {
      final messages = snap.docs.map(_docToLegacyMessage).toList();
      final idx = chat.indexWhere((c) => c.id.toString() == roomId);
      if (idx != -1) {
        // Replace the messages list on the legacy model
        chat[idx] = legacy.ChatModel(
          chat[idx].id,
          chat[idx].firstName,
          chat[idx].image,
          messages,
          chat[idx].email,
        );
        if (selectChat?.id == chat[idx].id) {
          selectChat = chat[idx];
          scrollToBottom(isDelayed: true);
        }
      }
      update();
    });
  }

  legacy.ChatModel _roomToLegacyModel(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final participants = List<String>.from(d['participants'] as List? ?? []);
    final otherUid = participants.firstWhere(
      (uid) => uid != _currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : '',
    );
    return legacy.ChatModel(
      doc.id.hashCode,
      d['displayName'] as String? ?? otherUid,
      '',
      [],
      d['email'] as String? ?? '',
    );
  }

  legacy.ChatMessageModel _docToLegacyMessage(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return legacy.ChatMessageModel(
      doc.id.hashCode,
      d['text'] as String? ?? '',
      (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      d['senderId'] == _currentUserId,
      '',
    );
  }

  // ── UI actions ───────────────────────────────────────────────────────────

  void onSelectChat(id) {
    selectedChat = id;
    update();
  }

  void onChangeChat(legacy.ChatModel selected) {
    selectChat = selected;
    _subscribeToMessages(selected.id.toString());
    update();
  }

  void onSearchChat(String query) {
    final input = query.toLowerCase();
    searchChat = chat.where((c) {
      final lastMsg = c.messages.lastOrNull?.message ?? '';
      return c.firstName.toLowerCase().contains(input) ||
          lastMsg.toLowerCase().contains(input);
    }).toList();
    update();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || selectChat == null) return;

    messageController.clear();

    try {
      await _db
          .collection('chats')
          .doc(selectChat!.id.toString())
          .collection('messages')
          .add({
        'senderId': _currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      scrollToBottom(isDelayed: true);
    } catch (_) {
      // Silently fail — message will not appear
    }
  }

  void scrollToBottom({bool isDelayed = false}) {
    final delay = isDelayed ? 400 : 0;
    Future.delayed(Duration(milliseconds: delay), () {
      if (scrollController?.hasClients == true) {
        scrollController!.animateTo(
          scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubicEmphasized,
        );
      }
    });
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      _nowTime++;
      timeText = Generator.getTextFromSeconds(time: _nowTime);
      update();
    });
  }

  @override
  void onClose() {
    _timer.cancel();
    _roomsSub?.cancel();
    for (final sub in _messageSubs.values) {
      sub.cancel();
    }
    messageController.dispose();
    scrollController?.dispose();
    super.onClose();
  }
}
