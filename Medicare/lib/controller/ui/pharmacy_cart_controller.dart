import 'package:get/get.dart';
import 'package:medicare/model/cart_model.dart';
import 'package:medicare/views/my_controller.dart';

class PharmacyCartController extends MyController {
  List<CartData> cart = [];

  @override
  void onInit() {
    CartData.dummyList.then((value) {
      cart = value;
      update();
    });
    super.onInit();
  }

  void incrementQuantity(CartData cart) {
    if(cart.quantity < 10) cart.quantity++;
    update();
  }

  void decrementQuantity(CartData cart) {
    if(cart.quantity > 1) cart.quantity--;
    update();
  }

  void goToCheckoutScreen(){
    Get.toNamed('/pharmacy_checkout');
  }
}
