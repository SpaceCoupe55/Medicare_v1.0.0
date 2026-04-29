import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/models/invoice_model.dart';
import 'package:medicare/views/my_controller.dart';

class InvoiceDetailController extends MyController {
  InvoiceModel? invoice;
  bool loading = true;
  bool updating = false;

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments as String?;
    if (id != null) _load(id);
  }

  Future<void> _load(String id) async {
    loading = true;
    update();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('invoices')
          .doc(id)
          .get();
      if (doc.exists) invoice = InvoiceModel.fromFirestore(doc);
    } catch (_) {}
    loading = false;
    update();
  }

  Future<void> recordPayment({
    required InvoicePaymentMethod method,
    String? momoPhone,
    String? momoNetwork,
    String? momoReference,
  }) async {
    if (invoice == null) return;
    updating = true;
    update();
    try {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoice!.id)
          .update({
        'status': 'paid',
        'paymentMethod': method.name,
        'momoPhone': momoPhone,
        'momoNetwork': momoNetwork,
        'momoReference': momoReference,
        'paidAt': Timestamp.fromDate(DateTime.now()),
      });
      await _load(invoice!.id);
      Get.snackbar('Payment recorded', 'Invoice marked as paid.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (_) {
      Get.snackbar('Error', 'Failed to record payment.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      updating = false;
      update();
    }
  }

  Future<void> submitNhisClaim() async {
    if (invoice == null) return;
    updating = true;
    update();
    try {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoice!.id)
          .update({
        'nhisClaimStatus': 'submitted',
        'status': 'claimed',
      });
      await _load(invoice!.id);
      Get.snackbar('Claim submitted', 'NHIS claim marked as submitted.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (_) {
      Get.snackbar('Error', 'Failed to submit claim.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      updating = false;
      update();
    }
  }

  Future<void> updateClaimStatus(String status) async {
    if (invoice == null) return;
    updating = true;
    update();
    try {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoice!.id)
          .update({'nhisClaimStatus': status});
      await _load(invoice!.id);
    } catch (_) {
      Get.snackbar('Error', 'Failed to update claim.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      updating = false;
      update();
    }
  }
}
