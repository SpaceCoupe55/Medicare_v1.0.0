import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/patient_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

const List<String> kBloodTypes = [
  'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
];

class PatientListController extends MyController {
  // ── Raw list from Firestore ────────────────────────────────────────────────
  List<PatientModel> _allPatients = [];

  // ── Filtered list rendered by the view ────────────────────────────────────
  List<PatientModel> patients = [];

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  // ── Search / filter state ─────────────────────────────────────────────────
  final searchTE = TextEditingController();
  String _query = '';
  String? genderFilter;
  String? bloodTypeFilter;
  Timer? _debounce;

  int get totalCount => _allPatients.length;
  bool get hasData => _allPatients.isNotEmpty;

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
      _allPatients = [];
      _query = '';
      genderFilter = null;
      bloodTypeFilter = null;
      searchTE.clear();
    }

    if (!hasMore) return;

    if (_allPatients.isEmpty) {
      loading = true;
    } else {
      loadingMore = true;
    }
    errorMessage = null;
    update();

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('patients')
          .where('hospitalId', isEqualTo: _hospitalId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snap = await query.get();
      final newItems = snap.docs.map(PatientModel.fromFirestore).toList();

      _allPatients.addAll(newItems);
      _lastDocument = snap.docs.isNotEmpty ? snap.docs.last : null;
      hasMore = snap.docs.length == _pageSize;
    } catch (_) {
      errorMessage = 'Failed to load patients. Please try again.';
    } finally {
      loading = false;
      loadingMore = false;
      _applyFilter();
    }
  }

  void _applyFilter() {
    final q = _query.toLowerCase().trim();
    patients = _allPatients.where((p) {
      if (genderFilter != null &&
          p.gender.toLowerCase() != genderFilter!.toLowerCase()) {
        return false;
      }
      if (bloodTypeFilter != null &&
          p.bloodGroup.toLowerCase() != bloodTypeFilter!.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) { return true; }
      return p.name.toLowerCase().contains(q) ||
          p.mobileNumber.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.bloodGroup.toLowerCase().contains(q);
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

  void setGenderFilter(String? value) {
    genderFilter = (genderFilter == value) ? null : value;
    _applyFilter();
  }

  void setBloodTypeFilter(String? value) {
    bloodTypeFilter = (bloodTypeFilter == value) ? null : value;
    _applyFilter();
  }

  Future<void> refreshList() => _loadPage(isRefresh: true);

  Future<void> loadMore() async {
    if (!loadingMore && hasMore) await _loadPage();
  }

  Future<void> deletePatient(String id) async {
    try {
      await FirebaseFirestore.instance.collection('patients').doc(id).delete();
      _allPatients.removeWhere((p) => p.id == id);
      _applyFilter();
      Get.snackbar('Deleted', 'Patient deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
    } catch (_) {
      errorMessage = 'Failed to delete patient.';
      update();
      Get.snackbar('Error', 'Failed to delete patient.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
    }
  }

  void goDetailScreen(PatientModel patient) =>
      Get.toNamed(AppRoutes.patientDetail, arguments: patient);

  void goEditScreen(PatientModel patient) =>
      Get.toNamed(AppRoutes.patientEdit, arguments: patient);

  void addPatient() => Get.toNamed(AppRoutes.patientAdd);

  @override
  void onClose() {
    searchTE.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}
