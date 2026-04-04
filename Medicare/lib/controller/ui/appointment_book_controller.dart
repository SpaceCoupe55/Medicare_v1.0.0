import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/ui/appointment_list_controller.dart';
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

  late TextEditingController patientNameTE, patientLastNameTE,
      patientEmailTE, patientPhoneTE, notesTE;

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    patientNameTE     = TextEditingController();
    patientLastNameTE = TextEditingController();
    patientEmailTE    = TextEditingController();
    patientPhoneTE    = TextEditingController();
    notesTE           = TextEditingController();
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
      // Non-fatal: dropdown will be empty
    } finally {
      loadingDoctors = false;
      update();
    }
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
      orElse: () => availableDoctors.first,
    );
    selectedDoctorId = match.id;
    update();
  }

  Future<void> submit() async {
    final patientName =
        '${patientNameTE.text.trim()} ${patientLastNameTE.text.trim()}'.trim();
    if (patientName.isEmpty || selectedDate == null) {
      errorMessage = 'Please fill in patient name and appointment date.';
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

      final docRef = await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': '',
        'patientName': patientName,
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

      // Notify the assigned doctor
      if (selectedDoctorId.isNotEmpty) {
        final pad = (int n) => n.toString().padLeft(2, '0');
        final formatted =
            '${pad(dt.day)}/${pad(dt.month)}/${dt.year} ${pad(dt.hour)}:${pad(dt.minute)}';
        FirebaseFirestore.instance.collection('notifications').add({
          'userId': selectedDoctorId,
          'title': 'New appointment booked',
          'body': 'Patient $patientName scheduled for $formatted',
          'type': 'appointment_booked',
          'read': false,
          'relatedId': docRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      try { Get.find<AppointmentListController>().refreshList(); } catch (_) {}

      Get.snackbar('Success', 'Appointment booked successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
      Get.back();
    } catch (_) {
      errorMessage = 'Failed to book appointment. Please try again.';
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
    patientNameTE.dispose();
    patientLastNameTE.dispose();
    patientEmailTE.dispose();
    patientPhoneTE.dispose();
    notesTE.dispose();
    super.onClose();
  }
}
