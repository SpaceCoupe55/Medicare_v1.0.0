import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/ui/pharmacy_list_controller.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

class PharmacyAddController extends MyController {
  bool saving = false;
  String? errorMessage;

  late TextEditingController nameTE, categoryTE, priceTE, stockTE, rateTE;

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    nameTE     = TextEditingController();
    categoryTE = TextEditingController();
    priceTE    = TextEditingController();
    stockTE    = TextEditingController();
    rateTE     = TextEditingController();
    super.onInit();
  }

  Future<void> saveItem() async {
    if (nameTE.text.trim().isEmpty) {
      errorMessage = 'Item name is required.';
      update();
      return;
    }

    saving = true;
    errorMessage = null;
    update();

    try {
      final price = double.tryParse(priceTE.text.trim()) ?? 0.0;
      final stock = int.tryParse(stockTE.text.trim()) ?? 0;
      final rate  = double.tryParse(rateTE.text.trim()) ?? 0.0;

      await FirebaseFirestore.instance.collection('pharmacy').add({
        'name': nameTE.text.trim(),
        'category': categoryTE.text.trim(),
        'price': price,
        'stock': stock,
        'rate': rate,
        'imageUrl': '',
        'hospitalId': _hospitalId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      try { Get.find<PharmacyListController>().refreshList(); } catch (_) {}

      Get.snackbar('Success', 'Item added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
      Get.toNamed(AppRoutes.pharmacyList);
    } catch (_) {
      errorMessage = 'Failed to save item. Please try again.';
      Get.snackbar('Error', errorMessage!,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
    } finally {
      saving = false;
      update();
    }
  }

  @override
  void onClose() {
    nameTE.dispose();
    categoryTE.dispose();
    priceTE.dispose();
    stockTE.dispose();
    rateTE.dispose();
    super.onClose();
  }
}
