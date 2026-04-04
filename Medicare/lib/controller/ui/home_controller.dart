import 'package:get/get.dart';
import 'package:medicare/views/my_controller.dart';

class HomeController extends MyController {
  int selectedDiseases = 0;
  List diseases = [
    {"name": "Orthopedists"},
    {"name": "Obesity"},
    {"name": "Neck pain"},
    {"name": "Neurology"},
    {"name": "Headache"},
    {"name": "Shoulder"},
    {"name": "Eye care"}
  ];

  List doctorList = [
    {"name": "Benjamin", "specialization": "Neurosurgeon"},
    {"name": "Connor", "specialization": "Psychiatrist"},
    {"name": "Harry", "specialization": "Gynecologist"},
    {"name": "Leonard", "specialization": "Neurologist"},
    {"name": "Piers", "specialization": "Gynecologist"},
    {"name": "Simon", "specialization": "Psychiatrist"},
  ];

  List products = [
    {"name": "Detol", "image": "assets/images/products/detol.jpg", "price": 40, "rate": 4.5},
    {"name": "Nicotext", "image": "assets/images/products/nicotext.jpg", "price": 10, "rate": 5.0},
    {"name": "Pulse Oximeter", "image": "assets/images/products/pulse_oximeter.jpg", "price": 12, "rate": 4.0},
    {"name": "Sanitizer", "image": "assets/images/products/sanitizer.jpg", "price": 20, "rate": 3.5},
    {"name": "Stethoscope", "image": "assets/images/products/stethoscope.jpg", "price": 50, "rate": 5.0},
    {"name": "Thermometer", "image": "assets/images/products/thermometer.jpg", "price": 40, "rate": 5.0},
  ];

  void onSelectDiseases(value) {
    selectedDiseases = value;
    update();
  }

  void goToDetails() {
    Get.toNamed('/detail');
  }

  void seeAllProducts() {
    Get.toNamed('/pharmacy_list');
  }

  void goToDetailScreen() {
    Get.toNamed('/admin/patient/detail');
  }
}
