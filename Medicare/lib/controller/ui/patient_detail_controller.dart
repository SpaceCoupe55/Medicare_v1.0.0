import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/helpers/utils/my_utils.dart';
import 'package:medicare/models/patient_model.dart';
import 'package:medicare/views/my_controller.dart';

class PatientDetailController extends MyController {
  List<String> dummyTexts = List.generate(12, (index) => MyTextUtils.getDummyText(60));

  PatientModel? patient;
  bool loading = false;
  String? errorMessage;

  String get _patientId => Get.arguments as String? ?? '';

  @override
  void onInit() {
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
        patient = PatientModel.fromFirestore(doc);
      } else {
        errorMessage = 'Patient not found.';
      }
    } catch (_) {
      errorMessage = 'Failed to load patient details.';
    } finally {
      loading = false;
      update();
    }
  }
}
