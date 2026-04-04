import 'dart:math';

class Images {
  /// WebApps Logo ///
  static String logoSmall = 'assets/logo/logo_small.png';

  /// Background ///
  static String background = 'assets/images/dummy/dummy_1.jpg';

  static String counter = 'assets/dummy/counter.png';
  static String poster = 'assets/images/dummy/poster.jpg';

  /// Avatars ///
  static List<String> avatars = List.generate(10, (index) => 'assets/avatar/${index + 1}.png');

  static List<String> dummy = List.generate(3, (index) => 'assets/images/dummy/dummy_${index + 1}.jpg');
  static List<String> shirt = List.generate(7, (index) => 'assets/images/products/shirt_${index + 1}.png');
  static List<String> tShirt = List.generate(5, (index) => 'assets/images/products/t_shirt_${index + 1}.jpg');

  static String randomImage(List<String> images) {
    return images[Random().nextInt(images.length)];
  }
}
