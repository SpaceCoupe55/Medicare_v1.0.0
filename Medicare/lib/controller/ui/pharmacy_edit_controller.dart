import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/pharmacy_add_controller.dart';
import 'package:medicare/controller/ui/pharmacy_list_controller.dart';
import 'package:medicare/models/pharmacy_model.dart';
import 'package:medicare/views/my_controller.dart';

class PharmacyEditController extends MyController {
  late PharmacyModel _item;

  bool saving = false;
  String? errorMessage;

  late TextEditingController nameTE, categoryTE, priceTE, stockTE, descriptionTE;
  String selectedCategory = kPharmacyCategories.first;

  @override
  void onInit() {
    final args = Get.arguments;
    _item = args as PharmacyModel;

    selectedCategory = kPharmacyCategories.contains(_item.category)
        ? _item.category
        : kPharmacyCategories.first;

    nameTE        = TextEditingController(text: _item.name);
    categoryTE    = TextEditingController(text: _item.category);
    priceTE       = TextEditingController(text: _item.price.toString());
    stockTE       = TextEditingController(text: _item.stock.toString());
    descriptionTE = TextEditingController(text: _item.description);
    super.onInit();
  }

  void setCategory(String value) {
    selectedCategory = value;
    categoryTE.text  = value;
    update();
  }

  Future<void> saveItem() async {
    final name = nameTE.text.trim();
    final category = categoryTE.text.trim().isEmpty
        ? selectedCategory
        : categoryTE.text.trim();

    if (name.isEmpty) {
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

      await FirebaseFirestore.instance
          .collection('pharmacy')
          .doc(_item.id)
          .update({
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'description': descriptionTE.text.trim(),
      });

      try { Get.find<PharmacyListController>().refreshList(); } catch (_) {}

      Get.snackbar('Updated', 'Item updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      Get.back();
    } catch (_) {
      errorMessage = 'Failed to update item.';
      Get.snackbar('Error', 'Failed to update item.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
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
    descriptionTE.dispose();
    super.onClose();
  }
}
