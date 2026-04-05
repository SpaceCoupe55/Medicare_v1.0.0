import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/cart_controller.dart';
import 'package:medicare/models/pharmacy_model.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

class PharmacyListController extends MyController {
  // ── Raw + filtered lists ──────────────────────────────────────────────────
  List<PharmacyModel> _allItems = [];
  List<PharmacyModel> displayItems = [];

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  // ── Search / filter ───────────────────────────────────────────────────────
  final searchTE = TextEditingController();
  String _query = '';
  String? categoryFilter;
  Timer? _debounce;

  // ── Summary stats ─────────────────────────────────────────────────────────
  int get totalItemCount => _allItems.length;
  double get totalInventoryValue =>
      _allItems.fold(0.0, (s, i) => s + i.price * i.stock);

  List<String> get categoryOptions {
    final seen = <String>{};
    for (final i in _allItems) {
      final c = i.category.trim();
      if (c.isNotEmpty) { seen.add(c); }
    }
    return seen.toList()..sort();
  }

  bool get isAdmin =>
      AppAuthController.instance.user?.role == UserRole.admin;

  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 40;

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    super.onInit();
    _loadPage();
  }

  Future<void> _loadPage({bool isRefresh = false}) async {
    if (isRefresh) {
      _lastDocument = null;
      hasMore = true;
      _allItems = [];
      _query = '';
      categoryFilter = null;
      searchTE.clear();
    }

    if (!hasMore) { return; }

    if (_allItems.isEmpty) {
      loading = true;
    } else {
      loadingMore = true;
    }
    errorMessage = null;
    update();

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('pharmacy')
          .where('hospitalId', isEqualTo: _hospitalId)
          .orderBy('name')
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snap = await query.get();
      final newItems = snap.docs.map(PharmacyModel.fromFirestore).toList();

      _allItems.addAll(newItems);
      _lastDocument = snap.docs.isNotEmpty ? snap.docs.last : null;
      hasMore = snap.docs.length == _pageSize;
    } catch (_) {
      errorMessage = 'Failed to load inventory. Please try again.';
    } finally {
      loading = false;
      loadingMore = false;
      _applyFilter();
    }
  }

  void _applyFilter() {
    final q = _query.toLowerCase().trim();
    displayItems = _allItems.where((i) {
      if (categoryFilter != null &&
          i.category.toLowerCase() != categoryFilter!.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) { return true; }
      return i.name.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q);
    }).toList();
    update();
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _query = value;
    _debounce = Timer(const Duration(milliseconds: 300), _applyFilter);
  }

  void clearSearch() {
    _debounce?.cancel();
    searchTE.clear();
    _query = '';
    _applyFilter();
  }

  void setCategoryFilter(String? value) {
    categoryFilter = (categoryFilter == value) ? null : value;
    _applyFilter();
  }

  Future<void> refreshList() => _loadPage(isRefresh: true);

  Future<void> loadMore() async {
    if (!loadingMore && hasMore) { await _loadPage(); }
  }

  // ── Cart ──────────────────────────────────────────────────────────────────

  void addToCart(PharmacyModel item, int qty) {
    CartController.instance.addItem(item, qty: qty);
    Get.snackbar(
      'Added to cart',
      '${item.name} × $qty',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> deleteItem(String id) async {
    try {
      await FirebaseFirestore.instance.collection('pharmacy').doc(id).delete();
      _allItems.removeWhere((p) => p.id == id);
      _applyFilter();
      Get.snackbar('Deleted', 'Item deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
    } catch (_) {
      Get.snackbar('Error', 'Failed to delete item.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
    }
  }

  void goToAdd() => Get.toNamed(AppRoutes.pharmacyAdd);
  void goToEdit(PharmacyModel item) =>
      Get.toNamed(AppRoutes.pharmacyEdit, arguments: item);
  void goToCart() => Get.toNamed(AppRoutes.pharmacyCart);

  // Kept for compatibility (edit screen passes model back)
  PharmacyModel? getItemById(String id) {
    try { return _allItems.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }

  @override
  void onClose() {
    searchTE.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}
