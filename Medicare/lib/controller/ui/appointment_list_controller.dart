import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/appointment_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class AppointmentListController extends MyController {
  // ── Raw list from Firestore ────────────────────────────────────────────────
  List<AppointmentModel> _allAppointments = [];

  // ── Filtered list rendered by the view ────────────────────────────────────
  List<AppointmentModel> appointmentListModel = [];

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  // ── Search / filter state ─────────────────────────────────────────────────
  final searchTE = TextEditingController();
  String _query = '';
  AppointmentStatus? statusFilter;
  DateTime? fromDate;
  DateTime? toDate;
  Timer? _debounce;

  int get totalCount => _allAppointments.length;

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
      _allAppointments = [];
      _query = '';
      statusFilter = null;
      fromDate = null;
      toDate = null;
      searchTE.clear();
    }

    if (!hasMore) { return; }

    if (_allAppointments.isEmpty) {
      loading = true;
    } else {
      loadingMore = true;
    }
    errorMessage = null;
    update();

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('appointments')
          .where('hospitalId', isEqualTo: _hospitalId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snap = await query.get();
      final newItems = snap.docs.map(AppointmentModel.fromFirestore).toList();

      _allAppointments.addAll(newItems);
      _lastDocument = snap.docs.isNotEmpty ? snap.docs.last : null;
      hasMore = snap.docs.length == _pageSize;
    } catch (_) {
      errorMessage = 'Failed to load appointments. Please try again.';
    } finally {
      loading = false;
      loadingMore = false;
      _applyFilter();
    }
  }

  void _applyFilter() {
    final q = _query.toLowerCase().trim();
    appointmentListModel = _allAppointments.where((a) {
      if (statusFilter != null && a.status != statusFilter) { return false; }
      if (fromDate != null) {
        final from = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
        final aDate = DateTime(a.date.year, a.date.month, a.date.day);
        if (aDate.isBefore(from)) { return false; }
      }
      if (toDate != null) {
        final to = DateTime(toDate!.year, toDate!.month, toDate!.day);
        final aDate = DateTime(a.date.year, a.date.month, a.date.day);
        if (aDate.isAfter(to)) { return false; }
      }
      if (q.isEmpty) { return true; }
      return a.name.toLowerCase().contains(q) ||
          a.consultingDoctor.toLowerCase().contains(q) ||
          _fmtDate(a.date).contains(q);
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

  void setStatusFilter(AppointmentStatus? value) {
    statusFilter = (statusFilter == value) ? null : value;
    _applyFilter();
  }

  void setFromDate(DateTime? date) {
    fromDate = date;
    _applyFilter();
  }

  void setToDate(DateTime? date) {
    toDate = date;
    _applyFilter();
  }

  void clearDateRange() {
    fromDate = null;
    toDate = null;
    _applyFilter();
  }

  Future<void> refreshList() => _loadPage(isRefresh: true);

  Future<void> loadMore() async {
    if (!loadingMore && hasMore) { await _loadPage(); }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(id)
          .delete();
      _allAppointments.removeWhere((a) => a.id == id);
      _applyFilter();
      Get.snackbar('Deleted', 'Appointment deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
    } catch (_) {
      errorMessage = 'Failed to delete appointment.';
      update();
      Get.snackbar('Error', 'Failed to delete appointment.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
    }
  }

  void bookAppointment() => Get.toNamed(AppRoutes.appointmentBook);

  void goToSchedulingEditScreen(AppointmentModel appointment) =>
      Get.toNamed(AppRoutes.appointmentEdit, arguments: appointment);

  void goToSchedulingScreen() => Get.toNamed(AppRoutes.appointmentSchedule);

  void billAppointment(AppointmentModel appt) => Get.toNamed(
        AppRoutes.invoiceCreate,
        arguments: {
          'appointmentId': appt.id,
          'patientName': appt.name,
          'doctorName': appt.consultingDoctor,
        },
      );

  @override
  void onClose() {
    searchTE.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}
