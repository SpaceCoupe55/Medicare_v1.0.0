import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/helpers/utils/my_utils.dart';
import 'package:medicare/models/doctor_model.dart';
import 'package:medicare/views/my_controller.dart';

class DoctorDetailController extends MyController {
  List<String> dummyTexts = List.generate(12, (index) => MyTextUtils.getDummyText(60));

  DoctorModel? doctor;
  bool loading = false;
  String? errorMessage;

  String get _doctorId => Get.arguments as String? ?? '';

  @override
  void onInit() {
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
        doctor = DoctorModel.fromFirestore(doc);
      } else {
        errorMessage = 'Doctor not found.';
      }
    } catch (_) {
      errorMessage = 'Failed to load doctor details.';
    } finally {
      loading = false;
      update();
    }
  }
}
