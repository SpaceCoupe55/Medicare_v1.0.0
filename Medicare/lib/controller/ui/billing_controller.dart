import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/invoice_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

class BillingController extends MyController {
  List<InvoiceModel> invoices = [];
  bool loading = true;
  String filterStatus = 'all';

  StreamSubscription<QuerySnapshot>? _sub;

  List<InvoiceModel> get filtered {
    if (filterStatus == 'all') return invoices;
    return invoices.where((inv) => inv.status.name == filterStatus).toList();
  }

  int countFor(String status) =>
      invoices.where((inv) => inv.status.name == status).length;

  @override
  void onInit() {
    super.onInit();
    _subscribe();
  }

  void _subscribe() {
    final user = AppAuthController.instance.user;
    if (user == null) return;
    loading = true;
    update();
    _sub = FirebaseFirestore.instance
        .collection('invoices')
        .where('hospitalId', isEqualTo: user.hospitalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        invoices = snap.docs.map(InvoiceModel.fromFirestore).toList();
        loading = false;
        update();
      },
      onError: (_) {
        loading = false;
        update();
      },
    );
  }

  void setFilter(String status) {
    filterStatus = status;
    update();
  }

  void createNew() => Get.toNamed(AppRoutes.invoiceCreate);

  void openDetail(InvoiceModel inv) =>
      Get.toNamed(AppRoutes.invoiceDetail, arguments: inv.id);

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
