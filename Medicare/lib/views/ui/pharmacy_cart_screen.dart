import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/cart_controller.dart';
import 'package:medicare/controller/ui/pharmacy_cart_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/views/layout/layout.dart';

class PharmacyCartScreen extends StatefulWidget {
  const PharmacyCartScreen({super.key});

  @override
  State<PharmacyCartScreen> createState() => _PharmacyCartScreenState();
}

class _PharmacyCartScreenState extends State<PharmacyCartScreen> with UIMixin {
  final PharmacyCartController controller = Get.put(PharmacyCartController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: MySpacing.x(flexSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText.titleMedium('Cart', fontSize: 18, fontWeight: 600),
                MyBreadcrumb(
                  children: [
                    MyBreadcrumbItem(name: 'Pharmacy'),
                    MyBreadcrumbItem(name: 'Cart', active: true),
                  ],
                ),
              ],
            ),
          ),
          MySpacing.height(flexSpacing),
          Padding(
            padding: MySpacing.x(flexSpacing),
            child: Obx(() {
              final cart = CartController.instance;
              final items = cart.items;

              if (items.isEmpty) {
                return _emptyCart();
              }

              return LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 720;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _itemsPanel(cart)),
                      MySpacing.width(16),
                      SizedBox(width: 280, child: _summaryPanel(cart)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _itemsPanel(cart),
                    MySpacing.height(16),
                    _summaryPanel(cart),
                  ],
                );
              });
            }),
          ),
          MySpacing.height(flexSpacing),
        ],
      ),
    );
  }

  Widget _emptyCart() {
    return MyContainer(
      paddingAll: 40,
      borderRadiusAll: 12,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shopping_cart,
                size: 48, color: contentTheme.secondary.withAlpha(100)),
            MySpacing.height(16),
            MyText.titleMedium('Your cart is empty', fontWeight: 600),
            MySpacing.height(8),
            MyText.bodySmall('Add items from the pharmacy inventory.',
                muted: true),
            MySpacing.height(24),
            MyButton(
              onPressed: controller.continueShopping,
              elevation: 0,
              padding: MySpacing.xy(20, 12),
              backgroundColor: contentTheme.primary,
              borderRadiusAll: 8,
              child: MyText.labelMedium('Browse Inventory',
                  color: contentTheme.onPrimary, fontWeight: 600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemsPanel(CartController cart) {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shopping_cart,
                  size: 18, color: contentTheme.primary),
              MySpacing.width(8),
              MyText.titleMedium('Items', fontWeight: 600),
            ],
          ),
          MySpacing.height(16),
          // Header row
          Row(
            children: [
              Expanded(
                  flex: 4,
                  child: MyText.labelSmall('Item', muted: true)),
              SizedBox(
                  width: 110,
                  child: MyText.labelSmall('Qty',
                      muted: true, textAlign: TextAlign.center)),
              SizedBox(
                  width: 90,
                  child: MyText.labelSmall('Unit',
                      muted: true, textAlign: TextAlign.right)),
              SizedBox(
                  width: 90,
                  child: MyText.labelSmall('Total',
                      muted: true, textAlign: TextAlign.right)),
              const SizedBox(width: 36),
            ],
          ),
          const Divider(height: 16),
          ...cart.items.map((ci) => Obx(() => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Name + category
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.bodySmall(ci.item.name,
                              fontWeight: 600,
                              overflow: TextOverflow.ellipsis),
                          MyText.bodySmall(ci.item.category,
                              muted: true, fontSize: 11),
                        ],
                      ),
                    ),
                    // Qty stepper
                    SizedBox(
                      width: 110,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _qtyBtn(
                            icon: LucideIcons.minus,
                            onTap: () => cart.decrement(ci.item.id),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: MyText.bodySmall('${ci.quantity.value}',
                                fontWeight: 700),
                          ),
                          _qtyBtn(
                            icon: LucideIcons.plus,
                            onTap: () => cart.increment(ci.item.id),
                          ),
                        ],
                      ),
                    ),
                    // Unit price
                    SizedBox(
                      width: 90,
                      child: MyText.bodySmall(
                        'GHS ${ci.item.price.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        muted: true,
                      ),
                    ),
                    // Line total
                    SizedBox(
                      width: 90,
                      child: MyText.bodySmall(
                        'GHS ${ci.lineTotal.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        fontWeight: 600,
                      ),
                    ),
                    // Remove button
                    SizedBox(
                      width: 36,
                      child: IconButton(
                        icon: Icon(LucideIcons.trash_2,
                            size: 14, color: contentTheme.danger),
                        onPressed: () => cart.removeItem(ci.item.id),
                        splashRadius: 16,
                        tooltip: 'Remove',
                      ),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  Widget _summaryPanel(CartController cart) {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium('Order Summary', fontWeight: 600),
          MySpacing.height(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.bodySmall('Items', muted: true),
              MyText.bodySmall('${cart.totalItems}'),
            ],
          ),
          MySpacing.height(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.bodySmall('Subtotal', muted: true),
              MyText.bodySmall(
                  'GHS ${cart.subtotal.toStringAsFixed(2)}',
                  fontWeight: 600),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.titleMedium('Total', fontWeight: 700),
              MyText.titleMedium(
                'GHS ${cart.subtotal.toStringAsFixed(2)}',
                fontWeight: 700,
                color: contentTheme.primary,
              ),
            ],
          ),
          MySpacing.height(20),
          SizedBox(
            width: double.infinity,
            child: MyButton(
              onPressed: controller.goToCheckout,
              elevation: 0,
              padding: MySpacing.xy(16, 12),
              backgroundColor: contentTheme.primary,
              borderRadiusAll: 8,
              child: MyText.labelMedium('Proceed to Checkout',
                  color: contentTheme.onPrimary, fontWeight: 600),
            ),
          ),
          MySpacing.height(10),
          SizedBox(
            width: double.infinity,
            child: MyButton(
              onPressed: controller.continueShopping,
              elevation: 0,
              padding: MySpacing.xy(16, 12),
              backgroundColor: contentTheme.secondary.withAlpha(30),
              borderRadiusAll: 8,
              child: MyText.labelMedium('Continue Shopping',
                  color: contentTheme.onBackground, fontWeight: 600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: contentTheme.secondary.withAlpha(80)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 12, color: contentTheme.onBackground),
      ),
    );
  }
}
