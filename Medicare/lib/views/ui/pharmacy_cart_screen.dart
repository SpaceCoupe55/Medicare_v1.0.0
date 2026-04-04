import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/pharmacy_cart_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_list_extension.dart';
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
  PharmacyCartController controller = Get.put(PharmacyCartController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'pharmacy_cart_controller',
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium(
                      "Cart",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Cart', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing / 2),
                child: MyFlex(
                  children: [
                    MyFlexItem(
                        sizes: 'lg-9',
                        child: MyContainer(
                          paddingAll: 20,
                          borderRadiusAll: 12,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                                sortAscending: true,
                                columnSpacing: 195,
                                onSelectAll: (_) => {},
                                headingRowColor: WidgetStatePropertyAll(contentTheme.primary.withAlpha(40)),
                                border: TableBorder.all(
                                    borderRadius: BorderRadius.circular(12), style: BorderStyle.solid, width: .4, color: contentTheme.secondary),
                                dataRowMaxHeight: 100,
                                showBottomBorder: true,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                columns: [
                                  DataColumn(label: MyText.labelLarge('Product', color: contentTheme.primary)),
                                  DataColumn(label: MyText.labelLarge('Price', color: contentTheme.primary)),
                                  DataColumn(label: MyText.labelLarge('Qty', color: contentTheme.primary)),
                                  DataColumn(label: MyText.labelLarge('Total', color: contentTheme.primary)),
                                ],
                                rows: controller.cart
                                    .mapIndexed((index, data) => DataRow(cells: [
                                          DataCell(Row(
                                            children: [
                                              MyContainer(
                                                height: 56,
                                                width: 56,
                                                paddingAll: 0,
                                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                                child: Image.asset(
                                                  data.image,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              MySpacing.width(20),
                                              MyText.labelLarge(data.name, overflow: TextOverflow.ellipsis, maxLines: 1)
                                            ],
                                          )),
                                          DataCell(SizedBox(
                                            width: 100,
                                            child: MyText.bodySmall('\$${data.price}', fontWeight: 600),
                                          )),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                MyContainer.bordered(
                                                  paddingAll: 8,
                                                  borderRadiusAll: 8,
                                                  onTap: () => controller.decrementQuantity(data),
                                                  child: Icon(LucideIcons.minus, size: 16),
                                                ),
                                                MySpacing.width(12),
                                                MyContainer(
                                                    paddingAll: 0,
                                                    height: 32,
                                                    width: 32,
                                                    borderRadiusAll: 8,
                                                    color: contentTheme.primary,
                                                    child: Center(child: MyText.bodyMedium(data.quantity.toString(), color: contentTheme.onPrimary))),
                                                MySpacing.width(12),
                                                MyContainer.bordered(
                                                  paddingAll: 8,
                                                  borderRadiusAll: 8,
                                                  onTap: () => controller.incrementQuantity(data),
                                                  child: Icon(LucideIcons.plus, size: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(SizedBox(
                                            width: 100,
                                            child: MyText.bodySmall('${data.subTotal * data.quantity}', fontWeight: 600),
                                          )),
                                        ]))
                                    .toList()),
                          ),
                        )),
                    MyFlexItem(
                      sizes: 'lg-3',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyContainer(
                            borderRadiusAll: 12,
                            paddingAll: 0,
                            child: Column(
                              children: [
                                Padding(
                                  padding: MySpacing.nBottom(20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [MyText.bodyMedium("Subtotal", fontWeight: 600), MyText.bodyMedium("\$870")],
                                  ),
                                ),
                                MySpacing.height(20),
                                Padding(
                                  padding: MySpacing.x(20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [MyText.bodyMedium("Taxes", fontWeight: 600), MyText.bodyMedium("\$10")],
                                  ),
                                ),
                                Divider(height: 40),
                                Padding(
                                  padding: MySpacing.nTop(20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [MyText.bodyMedium("Total", fontWeight: 600), MyText.bodyMedium("\$860")],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          MySpacing.height(20),
                          MyContainer(
                            onTap: controller.goToCheckoutScreen,
                            color: contentTheme.primary,
                            borderRadiusAll: 8,
                            paddingAll: 12,
                            child: MyText.bodyMedium("Proceed to checkout", color: contentTheme.onPrimary),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
