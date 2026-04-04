import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/helpers/extention/string.dart';
import 'package:medicare/helpers/theme/admin_theme.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/models/notification_model.dart';
import 'package:medicare/views/my_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class NotificationController extends MyController {
  // ── Snackbar / banner demo UI (unchanged) ────────────────────────────────
  final TickerProvider ticker;
  Timer? _timer;

  TextEditingController toastTitleController =
      TextEditingController(text: "Medicare is awesome");
  ContentThemeColor selectedColor = ContentThemeColor.primary;
  SnackBarBehavior selectedBehavior = SnackBarBehavior.floating;
  late AnimationController animationController =
      AnimationController(vsync: ticker, duration: const Duration(seconds: 20));

  bool showCloseIcon = true,
      showOkAction = true,
      showBanner = false,
      showLeadingIcon = true,
      sticky = false;

  NotificationController(this.ticker);

  // ── Firestore notifications ──────────────────────────────────────────────
  List<NotificationModel> firestoreNotifications = [];
  bool loadingNotifications = false;
  StreamSubscription? _notifSub;

  String get _userId => AppAuthController.instance.user?.uid ?? '';

  int get unreadCount =>
      firestoreNotifications.where((n) => !n.read).length;

  @override
  void onInit() {
    super.onInit();
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    if (_userId.isEmpty) return;
    loadingNotifications = true;
    update();

    _notifSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      firestoreNotifications =
          snap.docs.map(NotificationModel.fromFirestore).toList();
      loadingNotifications = false;
      update();
    }, onError: (_) {
      loadingNotifications = false;
      update();
    });
  }

  Future<void> markAsRead(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .update({'read': true});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final unread =
        firestoreNotifications.where((n) => !n.read).toList();
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

  // ── Snackbar / banner helpers (unchanged) ────────────────────────────────

  void setBannerType(bool value) {
    showBanner = value;
    update();
  }

  void onChangeColor(ContentThemeColor? value) {
    if (value != null) {
      selectedColor = value;
      update();
    }
  }

  void onChangeBehavior(SnackBarBehavior? value) {
    if (value != null) {
      selectedBehavior = value;
      update();
    }
  }

  void onChangeShowCloseIcon(bool? value) {
    if (value != null) {
      showCloseIcon = value;
      update();
    }
  }

  void onAction(bool? value) {
    if (value != null) {
      showBanner ? showLeadingIcon = value : showOkAction = value;
      update();
    }
  }

  void onChangeSticky(bool? value) {
    if (value != null) {
      sticky = value;
      update();
    }
  }

  void show() {
    showBanner ? showMaterialBanner() : showSnackBar();
  }

  void showMaterialBanner() {
    String text =
        toastTitleController.text.nullIfEmpty ?? "Please set title";
    Color backgroundColor = selectedColor.color;
    Color color = selectedColor.onColor;

    List<Widget> actions = [];
    if (showCloseIcon) {
      actions.add(MyButton.text(
          onPressed: () {
            ScaffoldMessenger.of(Get.context!)
                .hideCurrentMaterialBanner();
          },
          padding: MySpacing.x(8),
          splashColor: color.withValues(alpha: 0.1),
          child: MyText.labelMedium('Dismiss', color: color)));
    } else {
      actions.add(MySpacing.empty());
    }

    Widget? leadingIcon;
    if (showLeadingIcon) {
      leadingIcon = Icon(LucideIcons.info, color: color, size: 20);
    }

    final banner = MaterialBanner(
      content: MyText.labelMedium(text, color: color),
      padding: MySpacing.x(24),
      leading: leadingIcon,
      actions: actions,
      overflowAlignment: OverflowBarAlignment.center,
      forceActionsBelow: false,
      backgroundColor: backgroundColor,
    );

    ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(Get.context!).showMaterialBanner(banner);

    _timer?.cancel();
    if (!sticky) {
      _timer = Timer(const Duration(seconds: 3), () {
        ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      });
    }
  }

  void showSnackBar() {
    String text =
        toastTitleController.text.nullIfEmpty ?? "Please set title";
    Color backgroundColor = selectedColor.color;
    Color color = selectedColor.onColor;
    double? width =
        selectedBehavior == SnackBarBehavior.fixed ? null : 300;
    Duration duration =
        Duration(seconds: sticky ? 10000 : 3);

    SnackBarAction? action;
    if (showOkAction) {
      action = SnackBarAction(
        label: "Ok",
        onPressed: () =>
            ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar(),
        textColor: color,
      );
    }

    final snackBar = SnackBar(
      width: width,
      behavior: selectedBehavior,
      duration: duration,
      showCloseIcon: showCloseIcon,
      closeIconColor: color,
      action: action,
      animation: Tween<double>(begin: 0, end: 300)
          .animate(animationController),
      content: MyText.labelLarge(text, color: color),
      backgroundColor: backgroundColor,
    );
    ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
    ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    super.dispose();
    _notifSub?.cancel();
    _timer?.cancel();
    try {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      ScaffoldMessenger.of(Get.context!)
          .hideCurrentMaterialBanner();
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }
}
