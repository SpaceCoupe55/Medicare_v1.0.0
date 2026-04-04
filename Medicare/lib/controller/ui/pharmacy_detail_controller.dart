import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/helpers/widgets/my_text_utils.dart';
import 'package:medicare/models/pharmacy_model.dart';
import 'package:medicare/views/my_controller.dart';

class PharmacyDetailController extends MyController {
  int animatedCarouselSize = 3;
  int selectedAnimatedCarousel = 0;
  int quantity = 1;
  Timer? timerAnimation;
  final PageController animatedPageController = PageController(initialPage: 0);
  List<String> dummyTexts = List.generate(12, (index) => MyTextUtils.getDummyText(60));

  // Pharmacy item detail
  PharmacyModel? currentItem;
  bool loading = false;
  String? errorMessage;

  // Related products kept as maps so existing UI access syntax (product['name']) works
  List<Map<String, dynamic>> products = [];

  String get _itemId => Get.arguments as String? ?? '';

  @override
  void onInit() {
    timerAnimation = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (selectedAnimatedCarousel < animatedCarouselSize - 1) {
        selectedAnimatedCarousel++;
      } else {
        selectedAnimatedCarousel = 0;
      }
      animatedPageController.animateToPage(
        selectedAnimatedCarousel,
        duration: const Duration(milliseconds: 600),
        curve: Curves.ease,
      );
      update();
    });
    super.onInit();
    _loadItem();
  }

  Future<void> _loadItem() async {
    loading = true;
    update();
    try {
      if (_itemId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('pharmacy')
            .doc(_itemId)
            .get();
        if (doc.exists) {
          currentItem = PharmacyModel.fromFirestore(doc);
        }
      }

      // Load related products (same category or just a few items)
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('pharmacy')
          .limit(6);
      if (currentItem != null && _itemId.isNotEmpty) {
        query = FirebaseFirestore.instance
            .collection('pharmacy')
            .where('category', isEqualTo: currentItem!.category)
            .limit(6);
      }
      final snap = await query.get();
      products = snap.docs
          .map(PharmacyModel.fromFirestore)
          .where((p) => p.id != _itemId)
          .map((p) => p.toDisplayMap())
          .toList();
    } catch (_) {
      errorMessage = 'Failed to load product details.';
    } finally {
      loading = false;
      update();
    }
  }

  void onChangeAnimatedCarousel(int value) {
    selectedAnimatedCarousel = value;
    update();
  }

  void incrementQuantity() {
    if (quantity < 10) quantity++;
    update();
  }

  void decrementQuantity() {
    if (quantity > 1) quantity--;
    update();
  }

  @override
  void onClose() {
    timerAnimation?.cancel();
    animatedPageController.dispose();
    super.onClose();
  }

  void shopNow() {
    Get.toNamed('/pharmacy_checkout');
  }

  void addToCart() {
    Get.toNamed('/cart');
  }
}
