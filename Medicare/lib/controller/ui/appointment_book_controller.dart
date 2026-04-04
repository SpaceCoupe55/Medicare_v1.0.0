import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/helpers/widgets/my_form_validator.dart';
import 'package:medicare/models/doctor_model.dart';
import 'package:medicare/views/my_controller.dart';

enum Gender { male, female }

class AppointmentBookController extends MyController {
  Gender gender = Gender.male;
  DateTime? selectedDate;
  TimeOfDay? fromSelectedTime;
  TimeOfDay? toSelectedTime;
  MyFormValidator basicValidator = MyFormValidator();
  bool saving = false;
  bool loadingDoctors = false;
  String? errorMessage;

  List<DoctorModel> availableDoctors = [];
  String selectedConsultingDoctor = '';
  String selectedDoctorId = '';

  late TextEditingController patientNameTE, patientEmailTE,
      patientPhoneTE, notesTE;

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    patientNameTE  = TextEditingController();
    patientEmailTE = TextEditingController();
    patientPhoneTE = TextEditingController();
    notesTE        = TextEditingController();
    super.onInit();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    loadingDoctors = true;
    update();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('doctors')
          .where('hospitalId', isEqualTo: _hospitalId)
          .where('status', isEqualTo: 'active')
          .limit(50)
          .get();
      availableDoctors = snap.docs.map(DoctorModel.fromFirestore).toList();
      if (availableDoctors.isNotEmpty) {
        selectedConsultingDoctor = availableDoctors.first.doctorName;
        selectedDoctorId = availableDoctors.first.id;
      }
    } catch (_) {
      // Non-fatal: form still usable with manual entry
    } finally {
      loadingDoctors = false;
      update();
    }
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      selectedDate = picked;
      update();
    }
  }

  Future<void> fromPickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: Get.context!,
      initialTime: fromSelectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      fromSelectedTime = picked;
      update();
    }
  }

  Future<void> toPickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: Get.context!,
      initialTime: toSelectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      toSelectedTime = picked;
      update();
    }
  }

  void onChangeGender(Gender? value) {
    gender = value ?? gender;
    update();
  }

  void onSelectedConsultingDoctor(String value) {
    selectedConsultingDoctor = value;
    final match = availableDoctors.firstWhere(
      (d) => d.doctorName == value,
      orElse: () => availableDoctors.isNotEmpty ? availableDoctors.first : availableDoctors.first,
    );
    selectedDoctorId = match.id;
    update();
  }

  Future<void> submit() async {
    if (patientNameTE.text.trim().isEmpty || selectedDate == null) {
      errorMessage = 'Please fill in required fields.';
      update();
      return;
    }

    saving = true;
    errorMessage = null;
    update();

    try {
      final time = fromSelectedTime ?? TimeOfDay.now();
      final dt = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        time.hour,
        time.minute,
      );

      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': '',
        'patientName': patientNameTE.text.trim(),
        'patientPhone': patientPhoneTE.text.trim(),
        'patientEmail': patientEmailTE.text.trim(),
        'doctorId': selectedDoctorId,
        'doctorName': selectedConsultingDoctor,
        'dateTime': Timestamp.fromDate(dt),
        'status': 'scheduled',
        'notes': notesTE.text.trim(),
        'hospitalId': _hospitalId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.toNamed('/admin/appointment_scheduling');
    } catch (_) {
      errorMessage = 'Failed to book appointment. Please try again.';
    } finally {
      saving = false;
      update();
    }
  }

  @override
  void onClose() {
    patientNameTE.dispose();
    patientEmailTE.dispose();
    patientPhoneTE.dispose();
    notesTE.dispose();
    super.onClose();
  }
}
