import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/appointment_model.dart';
import 'package:medicare/models/doctor_model.dart';
import 'package:medicare/models/pharmacy_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

class DoctorPortalController extends MyController {
  // ── My profile ────────────────────────────────────────────────────────────
  DoctorModel? myProfile;
  bool loadingProfile = true;
  String? profileError;

  // ── Appointments ──────────────────────────────────────────────────────────
  List<AppointmentModel> todayAppointments = [];
  List<AppointmentModel> upcomingAppointments = [];
  bool loadingAppointments = false;
  StreamSubscription<QuerySnapshot>? _apptSub;

  // ── Pharmacy stock (cached for prescription dialog) ────────────────────────
  List<PharmacyModel> pharmacyItems = [];
  bool _pharmacyLoaded = false;

  String? get _myDoctorId => myProfile?.id;

  // ── Stats ─────────────────────────────────────────────────────────────────
  int get todayCount => todayAppointments.length;
  int get pendingCount =>
      todayAppointments.where((a) => a.status == AppointmentStatus.scheduled).length;
  int get upcomingCount => upcomingAppointments.length;

  @override
  void onInit() {
    super.onInit();
    _loadMyProfile();
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> _loadMyProfile() async {
    final user = AppAuthController.instance.user;
    if (user == null) {
      profileError = 'Not authenticated.';
      loadingProfile = false;
      update();
      return;
    }
    loadingProfile = true;
    update();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        myProfile = DoctorModel.fromFirestore(snap.docs.first);
        _subscribeToAppointments();
      } else {
        profileError = 'No doctor profile linked to this account.\n'
            'Ask an admin to set your email in your doctor profile.';
      }
    } catch (_) {
      profileError = 'Failed to load doctor profile.';
    } finally {
      loadingProfile = false;
      update();
    }
  }

  // ── Appointments (real-time, next 14 days) ─────────────────────────────────

  void _subscribeToAppointments() {
    if (_myDoctorId == null) return;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final rangeEnd = todayStart.add(const Duration(days: 14));

    loadingAppointments = true;
    update();

    _apptSub = FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: _myDoctorId)
        .where('dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('dateTime', isLessThan: Timestamp.fromDate(rangeEnd))
        .orderBy('dateTime')
        .snapshots()
        .listen(
      (snap) {
        final todayEnd = todayStart.add(const Duration(days: 1));
        final all =
            snap.docs.map(AppointmentModel.fromFirestore).toList();
        todayAppointments =
            all.where((a) => a.date.isBefore(todayEnd)).toList();
        upcomingAppointments =
            all.where((a) => !a.date.isBefore(todayEnd)).toList();
        loadingAppointments = false;
        update();
      },
      onError: (_) {
        loadingAppointments = false;
        update();
      },
    );
  }

  Future<void> markCompleted(AppointmentModel appt) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appt.id)
        .update({'status': 'completed'});
    // Stream auto-refreshes
  }

  Future<void> markCancelled(AppointmentModel appt) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appt.id)
        .update({'status': 'cancelled'});
  }

  // ── Pharmacy stock ─────────────────────────────────────────────────────────

  Future<void> loadPharmacyItems() async {
    if (_pharmacyLoaded) return;
    final user = AppAuthController.instance.user;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pharmacy')
          .where('hospitalId', isEqualTo: user.hospitalId)
          .where('stock', isGreaterThan: 0)
          .orderBy('stock')
          .orderBy('name')
          .get();
      pharmacyItems =
          snap.docs.map(PharmacyModel.fromFirestore).toList();
      _pharmacyLoaded = true;
    } catch (_) {}
    update();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void goToPatient(String patientId) {
    Get.toNamed(AppRoutes.patientDetail, arguments: patientId);
  }

  @override
  void onClose() {
    _apptSub?.cancel();
    super.onClose();
  }
}
