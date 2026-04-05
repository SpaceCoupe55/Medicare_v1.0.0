import 'package:get/get.dart';
import 'package:medicare/controller/cart_controller.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

// Cart page delegates entirely to the global CartController.
// This thin controller just provides navigation helpers.
class PharmacyCartController extends MyController {
  CartController get cart => CartController.instance;

  void goToCheckout() => Get.toNamed(AppRoutes.pharmacyCheckout);
  void continueShopping() => Get.toNamed(AppRoutes.pharmacyList);
}
