import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/helpers/widgets/my_form_validator.dart';
import 'package:medicare/helpers/widgets/my_text_utils.dart';
import 'package:medicare/models/doctor_model.dart';
import 'package:medicare/views/my_controller.dart';

enum Gender { male, female }

enum Department { Orthopedic, Radiology, Dentist, Neurology }

class DoctorEditController extends MyController {
  MyFormValidator basicValidator = MyFormValidator();
  Gender gender = Gender.male;
  DateTime? selectedDate;
  List<String> dummyTexts = List.generate(12, (index) => MyTextUtils.getDummyText(60));
  bool loading = false;
  bool saving = false;
  String? errorMessage;

  late TextEditingController firstNameTE, lastNameTE, userNameTE, educationTE,
      cityTE, stateTE, addressTE, mobileNumberTE, emailAddressTE,
      designationTE, countryTE, postalCodeTE, biographyTE;

  DoctorModel? _doctor;
  String get _doctorId => Get.arguments as String? ?? '';

  @override
  void onInit() {
    firstNameTE    = TextEditingController();
    lastNameTE     = TextEditingController();
    userNameTE     = TextEditingController();
    educationTE    = TextEditingController();
    cityTE         = TextEditingController();
    stateTE        = TextEditingController();
    addressTE      = TextEditingController();
    mobileNumberTE = TextEditingController();
    emailAddressTE = TextEditingController();
    designationTE  = TextEditingController();
    countryTE      = TextEditingController();
    postalCodeTE   = TextEditingController();
    biographyTE    = TextEditingController(text: dummyTexts[0]);
    super.onInit();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    if (_doctorId.isEmpty) return;
    loading = true;
    update();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(_doctorId)
          .get();
      if (doc.exists) {
        _doctor = DoctorModel.fromFirestore(doc);
        _populate();
      }
    } catch (_) {
      errorMessage = 'Failed to load doctor data.';
    } finally {
      loading = false;
      update();
    }
  }

  void _populate() {
    final d = _doctor!;
    final parts = d.doctorName.split(' ');
    firstNameTE.text    = parts.first;
    lastNameTE.text     = parts.length > 1 ? parts.skip(1).join(' ') : '';
    userNameTE.text     = d.doctorName.toLowerCase().replaceAll(' ', '_');
    educationTE.text    = d.degree;
    mobileNumberTE.text = d.mobileNumber;
    emailAddressTE.text = d.email;
    designationTE.text  = d.designation;
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

  Future<void> saveChanges() async {
    if (_doctorId.isEmpty) return;
    saving = true;
    errorMessage = null;
    update();
    try {
      await FirebaseFirestore.instance.collection('doctors').doc(_doctorId).update({
        'name': '${firstNameTE.text.trim()} ${lastNameTE.text.trim()}'.trim(),
        'email': emailAddressTE.text.trim(),
        'phone': mobileNumberTE.text.trim(),
        'degree': educationTE.text.trim(),
        'specialization': designationTE.text.trim(),
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
    educationTE.dispose();
    cityTE.dispose();
    stateTE.dispose();
    addressTE.dispose();
    mobileNumberTE.dispose();
    emailAddressTE.dispose();
    designationTE.dispose();
    countryTE.dispose();
    postalCodeTE.dispose();
    biographyTE.dispose();
    super.onClose();
  }
}
