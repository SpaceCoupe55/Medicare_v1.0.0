import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/doctor_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

class DoctorListController extends MyController {
  // ── Raw list from Firestore ────────────────────────────────────────────────
  List<DoctorModel> _allDoctors = [];

  // ── Filtered list rendered by the view ────────────────────────────────────
  List<DoctorModel> doctors = [];

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  // ── Search / filter state ─────────────────────────────────────────────────
  final searchTE = TextEditingController();
  String _query = '';
  String? specializationFilter;
  Timer? _debounce;

  int get totalCount => _allDoctors.length;

  // Unique specializations derived from loaded data
  List<String> get specializationOptions {
    final seen = <String>{};
    for (final d in _allDoctors) {
      final s = d.specialization.trim();
      if (s.isNotEmpty) { seen.add(s); }
    }
    final list = seen.toList()..sort();
    return list;
  }

  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 20;

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
      _allDoctors = [];
      _query = '';
      specializationFilter = null;
      searchTE.clear();
    }

    if (!hasMore) { return; }

    if (_allDoctors.isEmpty) {
      loading = true;
    } else {
      loadingMore = true;
    }
    errorMessage = null;
    update();

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('doctors')
          .where('hospitalId', isEqualTo: _hospitalId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snap = await query.get();
      final newItems = snap.docs.map(DoctorModel.fromFirestore).toList();

      _allDoctors.addAll(newItems);
      _lastDocument = snap.docs.isNotEmpty ? snap.docs.last : null;
      hasMore = snap.docs.length == _pageSize;
    } catch (_) {
      errorMessage = 'Failed to load doctors. Please try again.';
    } finally {
      loading = false;
      loadingMore = false;
      _applyFilter();
    }
  }

  void _applyFilter() {
    final q = _query.toLowerCase().trim();
    doctors = _allDoctors.where((d) {
      if (specializationFilter != null &&
          d.specialization.toLowerCase() !=
              specializationFilter!.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) { return true; }
      return d.doctorName.toLowerCase().contains(q) ||
          d.specialization.toLowerCase().contains(q) ||
          d.email.toLowerCase().contains(q);
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

  void setSpecializationFilter(String? value) {
    specializationFilter = (specializationFilter == value) ? null : value;
    _applyFilter();
  }

  Future<void> refreshList() => _loadPage(isRefresh: true);

  Future<void> loadMore() async {
    if (!loadingMore && hasMore) { await _loadPage(); }
  }

  Future<void> deleteDoctor(String id) async {
    try {
      await FirebaseFirestore.instance.collection('doctors').doc(id).delete();
      _allDoctors.removeWhere((d) => d.id == id);
      _applyFilter();
      Get.snackbar('Deleted', 'Doctor deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
    } catch (_) {
      errorMessage = 'Failed to delete doctor.';
      update();
      Get.snackbar('Error', 'Failed to delete doctor.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
    }
  }

  void goDetailDoctorScreen(DoctorModel doctor) =>
      Get.toNamed(AppRoutes.doctorDetail, arguments: doctor);

  void goEditDoctorScreen(DoctorModel doctor) =>
      Get.toNamed(AppRoutes.doctorEdit, arguments: doctor);

  void addDoctor() => Get.toNamed(AppRoutes.doctorAdd);

  @override
  void onClose() {
    searchTE.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}
