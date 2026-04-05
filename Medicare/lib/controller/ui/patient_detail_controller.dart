import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/appointment_model.dart';
import 'package:medicare/models/medical_record_model.dart';
import 'package:medicare/models/patient_model.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/views/my_controller.dart';

class PatientDetailController extends MyController {
  // ── Patient ────────────────────────────────────────────────────────────────
  PatientModel? patient;
  bool loadingPatient = false;
  String? errorMessage;

  // ── Overview ──────────────────────────────────────────────────────────────
  String? assignedDoctorName;
  bool loadingDoctor = false;

  // ── Medical records ───────────────────────────────────────────────────────
  List<MedicalRecordModel> records = [];
  bool loadingRecords = false;
  bool _recordsLoaded = false;
  StreamSubscription<QuerySnapshot>? _recordsSub;
  String? expandedRecordId;

  // ── Appointments ──────────────────────────────────────────────────────────
  List<AppointmentModel> appointments = [];
  bool loadingAppointments = false;
  bool _appointmentsLoaded = false;

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool get canAddRecord {
    final role = AppAuthController.instance.userRole;
    return role == UserRole.admin || role == UserRole.doctor;
  }

  String get patientId => patient?.id ?? '';
  int get totalVisits => records.length;
  DateTime? get lastVisitDate =>
      records.isNotEmpty ? records.first.visitDate : null;

  @override
  void onInit() {
    super.onInit();
    _initPatient();
  }

  void _initPatient() {
    final args = Get.arguments;
    if (args is PatientModel) {
      patient = args;
      update();
      _loadAssignedDoctor();
    } else if (args is String && args.isNotEmpty) {
      _loadPatientById(args);
    } else {
      errorMessage = 'Patient not found.';
      update();
    }
  }

  Future<void> _loadPatientById(String id) async {
    loadingPatient = true;
    update();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(id)
          .get();
      if (doc.exists) {
        patient = PatientModel.fromFirestore(doc);
        _loadAssignedDoctor();
      } else {
        errorMessage = 'Patient not found.';
      }
    } catch (_) {
      errorMessage = 'Failed to load patient.';
    } finally {
      loadingPatient = false;
      update();
    }
  }

  Future<void> _loadAssignedDoctor() async {
    final doctorId = patient?.assignedDoctorId ?? '';
    if (doctorId.isEmpty) return;
    loadingDoctor = true;
    update();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();
      if (doc.exists) {
        assignedDoctorName = doc.data()?['name'] as String?;
      }
    } catch (_) {}
    loadingDoctor = false;
    update();
  }

  // Called by the view when a tab is selected
  void onTabChanged(int index) {
    if (index == 1 && !_recordsLoaded) _subscribeToRecords();
    if (index == 2 && !_appointmentsLoaded) _loadAppointments();
  }

  // ── Records ───────────────────────────────────────────────────────────────

  void _subscribeToRecords() {
    if (patientId.isEmpty) return;
    _recordsLoaded = true;
    loadingRecords = true;
    update();
    _recordsSub = FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('records')
        .orderBy('visitDate', descending: true)
        .snapshots()
        .listen(
      (snap) {
        records = snap.docs.map(MedicalRecordModel.fromFirestore).toList();
        loadingRecords = false;
        update();
      },
      onError: (_) {
        loadingRecords = false;
        update();
      },
    );
  }

  void toggleExpanded(String recordId) {
    expandedRecordId = expandedRecordId == recordId ? null : recordId;
    update();
  }

  // ── Appointments ──────────────────────────────────────────────────────────

  Future<void> _loadAppointments() async {
    if (patientId.isEmpty) return;
    _appointmentsLoaded = true;
    loadingAppointments = true;
    update();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('dateTime', descending: true)
          .limit(50)
          .get();
      appointments = snap.docs.map(AppointmentModel.fromFirestore).toList();
    } catch (_) {
      // Composite index may still be building; silently fail
    } finally {
      loadingAppointments = false;
      update();
    }
  }

  @override
  void onClose() {
    _recordsSub?.cancel();
    super.onClose();
  }
}
