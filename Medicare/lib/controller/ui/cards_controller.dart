import 'package:medicare/helpers/widgets/my_text_utils.dart';

import 'package:medicare/views/my_controller.dart';

class CardsController extends MyController {
  List<String> dummyTexts = List.generate(12, (index) => MyTextUtils.getDummyText(60));
}
