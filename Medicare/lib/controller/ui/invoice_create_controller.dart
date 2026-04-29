import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/patient_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

enum InvoicePayMethod { cash, momo, nhis, insurance }
enum InvoiceMomoNetwork { mtn, vodafone, airteltigo }

class LineItemEntry {
  final TextEditingController descCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController qtyCtrl;
  String type;

  LineItemEntry({
    String desc = '',
    this.type = 'consultation',
    String price = '',
    String qty = '1',
  })  : descCtrl = TextEditingController(text: desc),
        priceCtrl = TextEditingController(text: price),
        qtyCtrl = TextEditingController(text: qty);

  double get unitPrice => double.tryParse(priceCtrl.text) ?? 0;
  int get qty => int.tryParse(qtyCtrl.text) ?? 1;
  double get lineTotal => unitPrice * qty;

  void dispose() {
    descCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
  }
}

class InvoiceCreateController extends MyController {
  // ── Patients ──────────────────────────────────────────────────────────────
  List<PatientModel> patients = [];
  PatientModel? selectedPatient;
  bool loadingPatients = true;

  // ── Line items ────────────────────────────────────────────────────────────
  List<LineItemEntry> lineItems = [];

  // ── NHIS ──────────────────────────────────────────────────────────────────
  final RxBool nhisApplied = false.obs;
  final TextEditingController nhisCoverageCtrl =
      TextEditingController(text: '50');

  // ── Payment ───────────────────────────────────────────────────────────────
  final Rx<InvoicePayMethod> paymentMethod = InvoicePayMethod.cash.obs;
  final Rx<InvoiceMomoNetwork> momoNetwork = InvoiceMomoNetwork.mtn.obs;
  final TextEditingController momoPhoneCtrl = TextEditingController();
  final TextEditingController momoReferenceCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  bool saving = false;
  String? appointmentId;

  static const List<String> itemTypes = [
    'consultation',
    'procedure',
    'lab',
    'other',
  ];

  double get subtotal =>
      lineItems.fold(0.0, (acc, i) => acc + i.lineTotal);

  double get nhisCoverageFraction =>
      ((double.tryParse(nhisCoverageCtrl.text) ?? 50).clamp(0, 100)) / 100;

  double get nhisAmount =>
      nhisApplied.value ? subtotal * nhisCoverageFraction : 0.0;

  double get netAmount => subtotal - nhisAmount;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      appointmentId = args['appointmentId'] as String?;
      final doctorName = args['doctorName'] as String?;
      lineItems.add(LineItemEntry(
        desc: doctorName != null
            ? 'Consultation — $doctorName'
            : 'Consultation',
        type: 'consultation',
        price: '50',
        qty: '1',
      ));
      _loadPatients(preselectedName: args['patientName'] as String?);
    } else {
      lineItems.add(LineItemEntry());
      _loadPatients();
    }
  }

  Future<void> _loadPatients({String? preselectedName}) async {
    final user = AppAuthController.instance.user;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('patients')
          .where('hospitalId', isEqualTo: user.hospitalId)
          .orderBy('name')
          .limit(200)
          .get();
      patients = snap.docs.map(PatientModel.fromFirestore).toList();
      if (preselectedName != null) {
        selectedPatient = patients.firstWhereOrNull(
            (p) => p.name.toLowerCase() == preselectedName.toLowerCase());
      }
    } catch (_) {}
    loadingPatients = false;
    update();
  }

  void selectPatient(PatientModel? p) {
    selectedPatient = p;
    update();
  }

  void addLineItem() {
    lineItems.add(LineItemEntry());
    update();
  }

  void removeLineItem(int index) {
    lineItems[index].dispose();
    lineItems.removeAt(index);
    update();
  }

  void setItemType(int index, String type) {
    lineItems[index].type = type;
    update();
  }

  void setPaymentMethod(InvoicePayMethod m) => paymentMethod.value = m;
  void setMomoNetwork(InvoiceMomoNetwork n) => momoNetwork.value = n;

  Future<void> save({bool markPaid = false}) async {
    if (selectedPatient == null) {
      Get.snackbar('Validation', 'Please select a patient.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final validItems = lineItems
        .where((i) => i.descCtrl.text.trim().isNotEmpty && i.unitPrice > 0)
        .toList();
    if (validItems.isEmpty) {
      Get.snackbar('Validation', 'Add at least one line item with a price.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (markPaid &&
        paymentMethod.value == InvoicePayMethod.momo &&
        momoPhoneCtrl.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Enter MoMo phone number.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    saving = true;
    update();
    try {
      final auth = AppAuthController.instance;
      final user = auth.user!;
      final now = DateTime.now();

      final items = validItems
          .map((i) => {
                'description': i.descCtrl.text.trim(),
                'type': i.type,
                'unitPrice': i.unitPrice,
                'qty': i.qty,
                'lineTotal': i.lineTotal,
              })
          .toList();

      final sub = validItems.fold(0.0, (s, i) => s + i.lineTotal);
      final coverage = nhisApplied.value ? nhisCoverageFraction : 0.0;
      final nhisAmt = sub * coverage;
      final net = sub - nhisAmt;

      final data = <String, dynamic>{
        'patientId': selectedPatient!.id,
        'patientName': selectedPatient!.name,
        'appointmentId': appointmentId,
        'saleId': null,
        'items': items,
        'subtotal': sub,
        'nhisApplied': nhisApplied.value,
        'nhisCoverage': coverage,
        'nhisAmount': nhisAmt,
        'netAmount': net,
        'nhisClaimStatus': 'none',
        'paymentMethod': markPaid ? paymentMethod.value.name : null,
        'momoPhone': markPaid && paymentMethod.value == InvoicePayMethod.momo
            ? momoPhoneCtrl.text.trim()
            : null,
        'momoNetwork':
            markPaid && paymentMethod.value == InvoicePayMethod.momo
                ? _networkLabel(momoNetwork.value)
                : null,
        'momoReference':
            markPaid && paymentMethod.value == InvoicePayMethod.momo
                ? momoReferenceCtrl.text.trim()
                : null,
        'status': markPaid ? 'paid' : 'pending',
        'hospitalId': user.hospitalId,
        'createdBy': auth.userName,
        'paidAt': markPaid ? Timestamp.fromDate(now) : null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final ref =
          await FirebaseFirestore.instance.collection('invoices').add(data);
      Get.offNamed(AppRoutes.invoiceDetail, arguments: ref.id);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save invoice.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      saving = false;
      update();
    }
  }

  String _networkLabel(InvoiceMomoNetwork n) {
    switch (n) {
      case InvoiceMomoNetwork.mtn:
        return 'MTN MoMo';
      case InvoiceMomoNetwork.vodafone:
        return 'Vodafone Cash';
      case InvoiceMomoNetwork.airteltigo:
        return 'AirtelTigo Money';
    }
  }

  @override
  void onClose() {
    for (final item in lineItems) {
      item.dispose();
    }
    nhisCoverageCtrl.dispose();
    momoPhoneCtrl.dispose();
    momoReferenceCtrl.dispose();
    super.onClose();
  }
}
