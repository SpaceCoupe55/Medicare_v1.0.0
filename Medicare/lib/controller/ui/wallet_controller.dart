import 'package:medicare/model/wallet_data.dart';
import 'package:medicare/views/my_controller.dart';

class WalletController extends MyController {
  List<WalletData> wallet = [];

  @override
  void onInit() {
    WalletData.dummyList.then((value) {
      wallet = value.sublist(0, 10);
      update();
    });
    super.onInit();
  }
}
