import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/helpers/widgets/my_form_validator.dart';
import 'package:medicare/models/patient_model.dart';
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

class PatientEditController extends MyController {
  MyFormValidator basicValidator = MyFormValidator();
  Gender gender = Gender.male;
  BloodType bloodType = BloodType.APlus;
  DateTime? selectedDate;
  bool loading = false;
  bool saving = false;
  String? errorMessage;

  late TextEditingController firstNameTE, lastNameTE, userNameTE, addressTE,
      suggerTE, mobileNumberTE, ageTE, bloodPressureTE, injuryTE;

  PatientModel? _patient;
  String get _patientId => Get.arguments as String? ?? '';

  @override
  void onInit() {
    firstNameTE    = TextEditingController();
    lastNameTE     = TextEditingController();
    userNameTE     = TextEditingController();
    addressTE      = TextEditingController();
    suggerTE       = TextEditingController();
    mobileNumberTE = TextEditingController();
    ageTE          = TextEditingController();
    bloodPressureTE = TextEditingController();
    injuryTE       = TextEditingController();
    super.onInit();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    if (_patientId.isEmpty) return;
    loading = true;
    update();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(_patientId)
          .get();
      if (doc.exists) {
        _patient = PatientModel.fromFirestore(doc);
        _populate();
      }
    } catch (_) {
      errorMessage = 'Failed to load patient data.';
    } finally {
      loading = false;
      update();
    }
  }

  void _populate() {
    final p = _patient!;
    final nameParts = p.name.split(' ');
    firstNameTE.text    = nameParts.first;
    lastNameTE.text     = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    userNameTE.text     = p.name.toLowerCase().replaceAll(' ', '_');
    addressTE.text      = p.address;
    mobileNumberTE.text = p.mobileNumber;
    ageTE.text          = '${p.age}';
    injuryTE.text       = p.medicalHistory;
    selectedDate        = p.birthDate;
    gender              = p.gender.toLowerCase() == 'female' ? Gender.female : Gender.male;
  }

  void onChangeGender(Gender? value) {
    gender = value ?? gender;
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

  Future<void> saveChanges() async {
    if (_patientId.isEmpty) return;
    saving = true;
    errorMessage = null;
    update();
    try {
      final dob = selectedDate ?? _patient?.birthDate ?? DateTime(1990);
      final now = DateTime.now();
      final age = now.year - dob.year -
          ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0);

      await FirebaseFirestore.instance.collection('patients').doc(_patientId).update({
        'name': '${firstNameTE.text.trim()} ${lastNameTE.text.trim()}'.trim(),
        'gender': gender.name,
        'phone': mobileNumberTE.text.trim(),
        'address': addressTE.text.trim(),
        'age': age,
        'dob': Timestamp.fromDate(dob),
        'medicalHistory': injuryTE.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Get.back();
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
    userNameTE.dispose();
    addressTE.dispose();
    suggerTE.dispose();
    mobileNumberTE.dispose();
    ageTE.dispose();
    bloodPressureTE.dispose();
    injuryTE.dispose();
    super.onClose();
  }
}
