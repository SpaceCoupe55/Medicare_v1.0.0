import 'package:get/get.dart';
import 'package:medicare/models/pharmacy_model.dart';

class CartItem {
  final PharmacyModel item;
  final RxInt quantity;

  CartItem({required this.item, int initialQty = 1})
      : quantity = RxInt(initialQty);

  double get lineTotal => item.price * quantity.value;
}

class CartController extends GetxController {
  static CartController get instance => Get.find<CartController>();

  final RxList<CartItem> items = <CartItem>[].obs;

  // ── Computed ──────────────────────────────────────────────────────────────

  int get totalItems => items.fold(0, (sum, ci) => sum + ci.quantity.value);

  double get subtotal =>
      items.fold(0.0, (sum, ci) => sum + ci.lineTotal);

  // ── Actions ───────────────────────────────────────────────────────────────

  void addItem(PharmacyModel item, {int qty = 1}) {
    final idx = items.indexWhere((ci) => ci.item.id == item.id);
    if (idx >= 0) {
      final existing = items[idx];
      final newQty = existing.quantity.value + qty;
      existing.quantity.value = newQty.clamp(1, item.stock);
    } else {
      items.add(CartItem(item: item, initialQty: qty.clamp(1, item.stock)));
    }
  }

  void removeItem(String itemId) {
    items.removeWhere((ci) => ci.item.id == itemId);
  }

  void increment(String itemId) {
    final ci = items.firstWhereOrNull((ci) => ci.item.id == itemId);
    if (ci != null && ci.quantity.value < ci.item.stock) {
      ci.quantity.value++;
    }
  }

  void decrement(String itemId) {
    final ci = items.firstWhereOrNull((ci) => ci.item.id == itemId);
    if (ci == null) { return; }
    if (ci.quantity.value > 1) {
      ci.quantity.value--;
    } else {
      removeItem(itemId);
    }
  }

  void setQty(String itemId, int qty) {
    final ci = items.firstWhereOrNull((ci) => ci.item.id == itemId);
    if (ci == null) { return; }
    if (qty <= 0) {
      removeItem(itemId);
    } else {
      ci.quantity.value = qty.clamp(1, ci.item.stock);
    }
  }

  void clear() => items.clear();
}
