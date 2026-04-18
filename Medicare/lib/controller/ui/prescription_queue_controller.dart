import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/cart_controller.dart';
import 'package:medicare/models/pharmacy_model.dart';
import 'package:medicare/models/prescription_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

class PrescriptionQueueController extends MyController {
  List<PrescriptionModel> pending = [];
  List<PrescriptionModel> fulfilled = [];
  bool loading = true;
  bool showFulfilled = false;

  StreamSubscription<QuerySnapshot>? _sub;

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  List<PrescriptionModel> get displayed => showFulfilled ? fulfilled : pending;

  @override
  void onInit() {
    super.onInit();
    _subscribe();
  }

  void _subscribe() {
    if (_hospitalId.isEmpty) return;
    loading = true;
    update();

    _sub = FirebaseFirestore.instance
        .collection('prescriptions')
        .where('hospitalId', isEqualTo: _hospitalId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snap) {
        final all = snap.docs.map(PrescriptionModel.fromFirestore).toList();
        pending =
            all.where((r) => r.status == PrescriptionStatus.pending).toList();
        fulfilled =
            all.where((r) => r.status == PrescriptionStatus.fulfilled).toList();
        loading = false;
        update();
      },
      onError: (_) {
        loading = false;
        update();
      },
    );
  }

  void toggleView() {
    showFulfilled = !showFulfilled;
    update();
  }

  // ── Fulfillment ────────────────────────────────────────────────────────────

  Future<void> fulfillPrescription(PrescriptionModel rx) async {
    // 1. Load pharmacy stock
    List<PharmacyModel> stock = [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pharmacy')
          .where('hospitalId', isEqualTo: _hospitalId)
          .get();
      stock = snap.docs.map(PharmacyModel.fromFirestore).toList();
    } catch (_) {}

    // 2. Clear cart and populate with matched items
    CartController.instance.clear();
    int matched = 0;
    for (final rxItem in rx.items) {
      final name = (rxItem['name'] as String? ?? '').toLowerCase().trim();
      if (name.isEmpty) continue;
      final match = stock.firstWhereOrNull(
          (p) => p.name.toLowerCase().trim() == name && p.stock > 0);
      if (match != null) {
        CartController.instance.addItem(match, qty: 1);
        matched++;
      }
    }

    if (matched == 0 && rx.items.isNotEmpty) {
      Get.snackbar(
        'No items matched',
        'None of the prescribed medicines were found in inventory. '
            'Add them manually in checkout.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } else if (matched < rx.items.length) {
      Get.snackbar(
        '$matched/${rx.items.length} items matched',
        'Some medicines were not found in inventory. Add them manually.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }

    // 3. Navigate to checkout with prescription context
    Get.toNamed(AppRoutes.pharmacyCheckout, arguments: rx);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
