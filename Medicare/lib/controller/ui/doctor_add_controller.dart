import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/ui/doctor_list_controller.dart';
import 'package:medicare/helpers/widgets/my_form_validator.dart';
import 'package:medicare/views/my_controller.dart';

enum Gender { male, female }

enum Department { Orthopedic, Radiology, Dentist, Neurology }

class DoctorAddController extends MyController {
  Gender gender = Gender.male;
  DateTime? selectedDate;
  MyFormValidator basicValidator = MyFormValidator();
  bool saving = false;
  String? errorMessage;

  late TextEditingController firstNameTE, lastNameTE, emailTE, phoneTE,
      degreeTE, specializationTE, addressTE, biographyTE;

  @override
  void onInit() {
    firstNameTE     = TextEditingController();
    lastNameTE      = TextEditingController();
    emailTE         = TextEditingController();
    phoneTE         = TextEditingController();
    degreeTE        = TextEditingController();
    specializationTE = TextEditingController();
    addressTE       = TextEditingController();
    biographyTE     = TextEditingController();
    super.onInit();
  }

  void onChangeGender(Gender? value) {
    gender = value ?? gender;
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

  Future<void> saveDoctor() async {
    final name =
        '${firstNameTE.text.trim()} ${lastNameTE.text.trim()}'.trim();
    if (name.isEmpty) {
      errorMessage = 'First name is required.';
      update();
      return;
    }

    saving = true;
    errorMessage = null;
    update();

    try {
      final user = AppAuthController.instance.user;
      await FirebaseFirestore.instance.collection('doctors').add({
        'name': name,
        'email': emailTE.text.trim(),
        'phone': phoneTE.text.trim(),
        'degree': degreeTE.text.trim(),
        'specialization': specializationTE.text.trim(),
        'avatarUrl': '',
        'hospitalId': user?.hospitalId ?? '',
        'status': 'active',
        'schedule': {},
        'createdAt': FieldValue.serverTimestamp(),
      });

      try { Get.find<DoctorListController>().refreshList(); } catch (_) {}

      Get.snackbar('Success', 'Doctor added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
      Get.back();
    } catch (_) {
      errorMessage = 'Failed to save doctor. Please try again.';
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
    emailTE.dispose();
    phoneTE.dispose();
    degreeTE.dispose();
    specializationTE.dispose();
    addressTE.dispose();
    biographyTE.dispose();
    super.onClose();
  }
}
