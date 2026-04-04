import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/models/appointment_model.dart';
import 'package:medicare/views/my_controller.dart';

enum Gender { male, female }

class AppointmentEditController extends MyController {
  Gender gender = Gender.male;
  bool loading = false;
  bool saving = false;
  String? errorMessage;

  late TextEditingController firstNameTE, lastNameTE, mobileNumberTE,
      emailTE, addressTE, treatmentTE;

  DateTime? selectedDate;
  TimeOfDay? fromSelectedTime;
  TimeOfDay? toSelectedTime;
  String selectedConsultingDoctor = '';

  AppointmentModel? _appointment;
  String get _appointmentId => Get.arguments as String? ?? '';

  @override
  void onInit() {
    firstNameTE    = TextEditingController();
    lastNameTE     = TextEditingController();
    mobileNumberTE = TextEditingController();
    emailTE        = TextEditingController();
    addressTE      = TextEditingController();
    treatmentTE    = TextEditingController();
    super.onInit();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    if (_appointmentId.isEmpty) {
      // No ID: pre-fill with defaults for a new edit session
      selectedDate      = DateTime.now();
      fromSelectedTime  = const TimeOfDay(hour: 8, minute: 20);
      toSelectedTime    = const TimeOfDay(hour: 9, minute: 20);
      firstNameTE.text  = 'Andrea';
      lastNameTE.text   = 'Buckland';
      mobileNumberTE.text = '123 345 3454';
      emailTE.text      = 'andrea@gmail.com';
      addressTE.text    = 'Akshya Nagar 1st Block 1st Cross, Bangalore-560016';
      treatmentTE.text  = 'Prostate';
      selectedConsultingDoctor = 'Bernardo james';
      return;
    }

    loading = true;
    update();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(_appointmentId)
          .get();
      if (doc.exists) {
        _appointment = AppointmentModel.fromFirestore(doc);
        _populate();
      }
    } catch (_) {
      errorMessage = 'Failed to load appointment data.';
    } finally {
      loading = false;
      update();
    }
  }

  void _populate() {
    final a = _appointment!;
    final nameParts = a.name.split(' ');
    firstNameTE.text    = nameParts.first;
    lastNameTE.text     = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    mobileNumberTE.text = a.mobile;
    emailTE.text        = a.email;
    treatmentTE.text    = a.treatment;
    selectedConsultingDoctor = a.consultingDoctor;
    selectedDate        = a.date;
    fromSelectedTime    = TimeOfDay(hour: a.time.hour, minute: a.time.minute);
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
    update();
  }

  Future<void> submit() async {
    if (_appointmentId.isEmpty) {
      Get.toNamed('/admin/appointment_scheduling');
      return;
    }

    saving = true;
    errorMessage = null;
    update();
    try {
      final time = fromSelectedTime ?? TimeOfDay.now();
      final date = selectedDate ?? DateTime.now();
      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(_appointmentId)
          .update({
        'patientName': '${firstNameTE.text.trim()} ${lastNameTE.text.trim()}'.trim(),
        'patientPhone': mobileNumberTE.text.trim(),
        'patientEmail': emailTE.text.trim(),
        'doctorName': selectedConsultingDoctor,
        'dateTime': Timestamp.fromDate(dt),
        'notes': treatmentTE.text.trim(),
      });
      Get.toNamed('/admin/appointment_scheduling');
    } catch (_) {
      errorMessage = 'Failed to save changes.';
    } finally {
      saving = false;
      update();
    }
  }

  @override
  void onClose() {
    firstNameTE.dispose();
    lastNameTE.dispose();
    mobileNumberTE.dispose();
    emailTE.dispose();
    addressTE.dispose();
    treatmentTE.dispose();
    super.onClose();
  }
}
