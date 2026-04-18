import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/cart_controller.dart';
import 'package:medicare/models/patient_model.dart';
import 'package:medicare/models/prescription_model.dart';
import 'package:medicare/models/sale_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

enum PaymentMethod { cash, momo }
enum MomoNetwork { mtn, vodafone, airteltigo }

class PharmacyCheckoutController extends MyController {
  CartController get cart => CartController.instance;

  // ── Prescription fulfillment context (set when coming from Rx queue) ───────
  PrescriptionModel? activePrescription;

  // ── Patient selection ─────────────────────────────────────────────────────
  List<PatientModel> patients = [];
  bool loadingPatients = false;
  PatientModel? selectedPatient;

  // ── Payment ───────────────────────────────────────────────────────────────
  Rx<PaymentMethod> paymentMethod = PaymentMethod.cash.obs;
  Rx<MomoNetwork> momoNetwork = MomoNetwork.mtn.obs;
  late TextEditingController momoPhoneTE;
  late TextEditingController momoReferenceTE;

  bool completing = false;

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    momoPhoneTE    = TextEditingController();
    momoReferenceTE = TextEditingController();
    super.onInit();
    // Check if launched from prescription queue
    final args = Get.arguments;
    if (args is PrescriptionModel) {
      activePrescription = args;
    }
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    if (_hospitalId.isEmpty) { return; }
    loadingPatients = true;
    update();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('patients')
          .where('hospitalId', isEqualTo: _hospitalId)
          .orderBy('name')
          .limit(100)
          .get();
      patients = snap.docs.map(PatientModel.fromFirestore).toList();
      // Pre-select patient from prescription context
      if (activePrescription != null) {
        selectedPatient = patients.firstWhereOrNull(
            (p) => p.id == activePrescription!.patientId);
        if (selectedPatient != null) {
          momoPhoneTE.text = selectedPatient!.mobileNumber;
        }
      }
    } catch (_) {}
    loadingPatients = false;
    update();
  }

  void selectPatient(PatientModel? p) {
    selectedPatient = p;
    if (p != null && momoPhoneTE.text.isEmpty) {
      momoPhoneTE.text = p.mobileNumber;
    }
    update();
  }

  void setPaymentMethod(PaymentMethod m) {
    paymentMethod.value = m;
    update();
  }

  void setMomoNetwork(MomoNetwork n) {
    momoNetwork.value = n;
    update();
  }

  Future<void> completeSale() async {
    if (cart.items.isEmpty) {
      Get.snackbar('Empty cart', 'Add items before completing a sale.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
      return;
    }

    if (paymentMethod.value == PaymentMethod.momo &&
        momoPhoneTE.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Enter MoMo phone number.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
      return;
    }

    completing = true;
    update();

    try {
      final uid   = AppAuthController.instance.user?.uid ?? '';
      final items = cart.items.map((ci) => SaleItem(
        pharmacyItemId: ci.item.id,
        name: ci.item.name,
        quantity: ci.quantity.value,
        unitPrice: ci.item.price,
        lineTotal: ci.lineTotal,
      )).toList();

      final grandTotal = cart.subtotal;
      final method = paymentMethod.value == PaymentMethod.cash ? 'cash' : 'momo';

      // (a+b) Write sale document
      final saleRef = FirebaseFirestore.instance.collection('sales').doc();
      final saleData = {
        'items': items.map((e) => e.toMap()).toList(),
        'grandTotal': grandTotal,
        'paymentMethod': method,
        'momoPhone': paymentMethod.value == PaymentMethod.momo
            ? momoPhoneTE.text.trim()
            : null,
        'momoNetwork': paymentMethod.value == PaymentMethod.momo
            ? _networkLabel(momoNetwork.value)
            : null,
        'momoReference': paymentMethod.value == PaymentMethod.momo
            ? (momoReferenceTE.text.trim().isEmpty
                ? null
                : momoReferenceTE.text.trim())
            : null,
        'patientId': selectedPatient?.id ?? activePrescription?.patientId,
        'prescriptionId': activePrescription?.id,
        'soldBy': uid,
        'hospitalId': _hospitalId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      };

      // (c) Decrement stock in a batch (batch is sufficient — stock is
      // display-only in real time; full race-condition safety would require
      // Cloud Functions which are outside Flutter scope).
      final batch = FirebaseFirestore.instance.batch();
      batch.set(saleRef, saleData);
      for (final ci in cart.items) {
        final ref = FirebaseFirestore.instance
            .collection('pharmacy')
            .doc(ci.item.id);
        batch.update(ref, {
          'stock': FieldValue.increment(-ci.quantity.value),
        });
      }

      // (d) Notify admin
      final adminSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('hospitalId', isEqualTo: _hospitalId)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      if (adminSnap.docs.isNotEmpty) {
        final adminId = adminSnap.docs.first.id;
        final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': adminId,
          'title': 'New pharmacy sale',
          'body': 'GHS ${grandTotal.toStringAsFixed(2)} sale completed via $method',
          'type': 'pharmacy_sale',
          'read': false,
          'relatedId': saleRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Mark prescription fulfilled (if applicable)
      if (activePrescription != null) {
        batch.update(
          FirebaseFirestore.instance
              .collection('prescriptions')
              .doc(activePrescription!.id),
          {
            'status': 'fulfilled',
            'saleId': saleRef.id,
            'fulfilledBy': uid,
            'fulfilledAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      // Build SaleModel for receipt
      final sale = SaleModel(
        id: saleRef.id,
        items: items,
        grandTotal: grandTotal,
        paymentMethod: method,
        momoPhone: paymentMethod.value == PaymentMethod.momo
            ? momoPhoneTE.text.trim()
            : null,
        momoNetwork: paymentMethod.value == PaymentMethod.momo
            ? _networkLabel(momoNetwork.value)
            : null,
        momoReference: momoReferenceTE.text.trim().isEmpty
            ? null
            : momoReferenceTE.text.trim(),
        patientId: selectedPatient?.id,
        soldBy: uid,
        hospitalId: _hospitalId,
        createdAt: DateTime.now(),
      );

      // (e) Clear cart
      CartController.instance.clear();

      // (f+g) Navigate to receipt
      Get.snackbar('Sale completed', 'Receipt generated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      Get.offNamed(AppRoutes.pharmacyReceipt, arguments: sale);
    } catch (e) {
      Get.snackbar('Error', 'Failed to complete sale. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      completing = false;
      update();
    }
  }

  String _networkLabel(MomoNetwork n) {
    switch (n) {
      case MomoNetwork.mtn: return 'MTN MoMo';
      case MomoNetwork.vodafone: return 'Vodafone Cash';
      case MomoNetwork.airteltigo: return 'AirtelTigo Money';
    }
  }

  @override
  void onClose() {
    momoPhoneTE.dispose();
    momoReferenceTE.dispose();
    super.onClose();
  }
}
