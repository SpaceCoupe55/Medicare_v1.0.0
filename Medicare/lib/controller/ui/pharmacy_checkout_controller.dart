import 'package:medicare/views/my_controller.dart';

class PharmacyCheckoutController extends MyController {
  bool isSaveInformation= false,isBillingAddress = false;

  void onSaveInformation(){
    isSaveInformation = !isSaveInformation;
    update();
  }

  void onBillingAddress(){
    isBillingAddress = !isBillingAddress;
    update();
  }
}