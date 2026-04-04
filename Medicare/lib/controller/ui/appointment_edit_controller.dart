import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/ui/appointment_list_controller.dart';
import 'package:medicare/models/appointment_model.dart';
import 'package:medicare/models/doctor_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

enum Gender { male, female }

class AppointmentEditController extends MyController {
  Gender gender = Gender.male;
  bool loading = false;
  bool saving = false;
  bool loadingDoctors = false;
  String? errorMessage;

  late TextEditingController firstNameTE, lastNameTE, mobileNumberTE,
      emailTE, addressTE, treatmentTE;

  DateTime? selectedDate;
  TimeOfDay? fromSelectedTime;
  TimeOfDay? toSelectedTime;

  AppointmentStatus selectedStatus = AppointmentStatus.scheduled;
  List<DoctorModel> availableDoctors = [];
  String selectedConsultingDoctor = '';
  String selectedDoctorId = '';

  AppointmentModel? _appointment;

  // Accept full AppointmentModel from nav arguments.
  AppointmentModel? get _argAppointment =>
      Get.arguments is AppointmentModel ? Get.arguments as AppointmentModel : null;

  String get _appointmentId => _argAppointment?.id ?? (Get.arguments as String? ?? '');

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    firstNameTE    = TextEditingController();
    lastNameTE     = TextEditingController();
    mobileNumberTE = TextEditingController();
    emailTE        = TextEditingController();
    addressTE      = TextEditingController();
    treatmentTE    = TextEditingController();
    super.onInit();
    _loadDoctors();
    _loadAppointment();
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
    } catch (_) {
      // Non-fatal
    } finally {
      loadingDoctors = false;
      update();
    }
  }

  Future<void> _loadAppointment() async {
    final arg = _argAppointment;
    if (arg != null) {
      _appointment = arg;
      _populate();
      return;
    }

    if (_appointmentId.isEmpty) {
      // No data: pre-fill with defaults for demo
      selectedDate     = DateTime.now();
      fromSelectedTime = const TimeOfDay(hour: 8, minute: 20);
      toSelectedTime   = const TimeOfDay(hour: 9, minute: 20);
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
    selectedDoctorId    = a.doctorId;
    selectedDate        = a.date;
    selectedStatus      = a.status;
    fromSelectedTime    = TimeOfDay(hour: a.time.hour, minute: a.time.minute);
    update();
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
    if (availableDoctors.isNotEmpty) selectedDoctorId = match.id;
    update();
  }

  void onSelectedStatus(AppointmentStatus value) {
    selectedStatus = value;
    update();
  }

  Future<void> submit() async {
    if (_appointmentId.isEmpty) {
      Get.toNamed(AppRoutes.appointmentList);
      return;
    }

    saving = true;
    errorMessage = null;
    update();
    try {
      final time = fromSelectedTime ?? TimeOfDay.now();
      final date = selectedDate ?? DateTime.now();
      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

      // Detect cancellation before writing
      final wasCancelled = _appointment?.status == AppointmentStatus.cancelled;
      final isNowCancelled = selectedStatus == AppointmentStatus.cancelled;

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(_appointmentId)
          .update({
        'patientName':
            '${firstNameTE.text.trim()} ${lastNameTE.text.trim()}'.trim(),
        'patientPhone': mobileNumberTE.text.trim(),
        'patientEmail': emailTE.text.trim(),
        'doctorId': selectedDoctorId,
        'doctorName': selectedConsultingDoctor,
        'dateTime': Timestamp.fromDate(dt),
        'status': selectedStatus.name,
        'notes': treatmentTE.text.trim(),
      });

      // Notify on cancellation (only when newly cancelled, not already cancelled)
      if (!wasCancelled && isNowCancelled) {
        String pad(int n) => n.toString().padLeft(2, '0');
        final formatted =
            '${pad(dt.day)}/${pad(dt.month)}/${dt.year} ${pad(dt.hour)}:${pad(dt.minute)}';
        final doctorId = selectedDoctorId.isNotEmpty
            ? selectedDoctorId
            : (_appointment?.doctorId ?? '');
        if (doctorId.isNotEmpty) {
          FirebaseFirestore.instance.collection('notifications').add({
            'userId': doctorId,
            'title': 'Appointment cancelled',
            'body': 'Appointment on $formatted has been cancelled',
            'type': 'appointment_cancelled',
            'read': false,
            'relatedId': _appointmentId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      try { Get.find<AppointmentListController>().refreshList(); } catch (_) {}

      Get.snackbar('Success', 'Appointment updated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
      Get.back();
    } catch (_) {
      errorMessage = 'Failed to save changes.';
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
    firstNameTE.dispose();
    lastNameTE.dispose();
    mobileNumberTE.dispose();
    emailTE.dispose();
    addressTE.dispose();
    treatmentTE.dispose();
    super.onClose();
  }
}
