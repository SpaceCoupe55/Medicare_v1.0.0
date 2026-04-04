import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/notification_model.dart';

/// Permanent singleton that drives the notification badge in the top bar.
/// Registered in main.dart with Get.put(..., permanent: true).
class AppNotificationController extends GetxController {
  static AppNotificationController get instance =>
      Get.find<AppNotificationController>();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool loading = false.obs;

  StreamSubscription? _sub;

  int get unreadCount => notifications.where((n) => !n.read).length;

  String get _userId => AppAuthController.instance.user?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    // Re-subscribe whenever the logged-in user changes
    ever(AppAuthController.instance.appUser, (_) => _subscribe());
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    if (_userId.isEmpty) {
      notifications.clear();
      return;
    }

    loading.value = true;

    _sub = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      notifications.value =
          snap.docs.map(NotificationModel.fromFirestore).toList();
      loading.value = false;
    }, onError: (_) {
      loading.value = false;
    });
  }

  Future<void> markAsRead(String id) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .update({'read': true});
  }

  Future<void> markAllAsRead() async {
    final unread = notifications.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final n in unread) {
      batch.update(
        FirebaseFirestore.instance.collection('notifications').doc(n.id),
        {'read': true},
      );
    }
    await batch.commit();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
