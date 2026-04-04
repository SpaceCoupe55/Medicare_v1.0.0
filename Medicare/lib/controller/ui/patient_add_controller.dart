import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/helpers/widgets/my_form_validator.dart';
import 'package:medicare/views/my_controller.dart';

enum Gender { male, female }

enum BloodType { APlus, AMinus, BPlus, BMinus, ABPlus, ABMinus, OPlus, OMinus }

extension BloodTypeExtension on BloodType {
  String get name {
    switch (this) {
      case BloodType.APlus:   return 'A+';
      case BloodType.AMinus:  return 'A-';
      case BloodType.BPlus:   return 'B+';
      case BloodType.BMinus:  return 'B-';
      case BloodType.ABPlus:  return 'AB+';
      case BloodType.ABMinus: return 'AB-';
      case BloodType.OPlus:   return 'O+';
      case BloodType.OMinus:  return 'O-';
    }
  }
}

class PatientAddController extends MyController {
  Gender gender = Gender.male;
  BloodType bloodType = BloodType.APlus;
  MyFormValidator basicValidator = MyFormValidator();
  DateTime? selectedDate;
  bool saving = false;
  String? errorMessage;

  late TextEditingController nameTE, phoneTE, emailTE, addressTE, medicalHistoryTE;

  @override
  void onInit() {
    nameTE = TextEditingController();
    phoneTE = TextEditingController();
    emailTE = TextEditingController();
    addressTE = TextEditingController();
    medicalHistoryTE = TextEditingController();
    super.onInit();
  }

  void onChangeGender(Gender? value) {
    gender = value ?? gender;
    update();
  }

  void onChangeBloodType(BloodType? value) {
    bloodType = value ?? bloodType;
    update();
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedDate = picked;
      update();
    }
  }

  Future<void> savePatient() async {
    if (nameTE.text.trim().isEmpty) {
      errorMessage = 'Name is required.';
      update();
      return;
    }

    saving = true;
    errorMessage = null;
    update();

    try {
      final user = AppAuthController.instance.user;
      final dob = selectedDate ?? DateTime(1990);
      final now = DateTime.now();
      final age = now.year - dob.year -
          ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0);

      await FirebaseFirestore.instance.collection('patients').add({
        'name': nameTE.text.trim(),
        'gender': gender.name,
        'phone': phoneTE.text.trim(),
        'email': emailTE.text.trim(),
        'address': addressTE.text.trim(),
        'bloodType': bloodType.name,
        'medicalHistory': medicalHistoryTE.text.trim(),
        'status': 'active',
        'age': age,
        'dob': Timestamp.fromDate(dob),
        'assignedDoctorId': '',
        'hospitalId': user?.hospitalId ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.back();
    } catch (e) {
      errorMessage = 'Failed to save patient. Please try again.';
    } finally {
      saving = false;
      update();
    }
  }

  @override
  void onClose() {
    nameTE.dispose();
    phoneTE.dispose();
    emailTE.dispose();
    addressTE.dispose();
    medicalHistoryTE.dispose();
    super.onClose();
  }
}
