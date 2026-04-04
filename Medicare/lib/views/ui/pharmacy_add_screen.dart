import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/pharmacy_add_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/views/layout/layout.dart';

class PharmacyAddScreen extends StatefulWidget {
  const PharmacyAddScreen({super.key});

  @override
  State<PharmacyAddScreen> createState() => _PharmacyAddScreenState();
}

class _PharmacyAddScreenState extends State<PharmacyAddScreen> with UIMixin {
  PharmacyAddController controller = Get.put(PharmacyAddController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'pharmacy_add_controller',
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('Add Pharmacy Item',
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Operations'),
                        MyBreadcrumbItem(name: 'Pharmacy', active: false),
                        MyBreadcrumbItem(name: 'Add Item', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: MyContainer(
                  paddingAll: 20,
                  borderRadiusAll: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText.titleMedium('Item Details', fontWeight: 600),
                      MySpacing.height(20),
                      if (controller.errorMessage != null) ...[
                        Container(
                          padding: MySpacing.all(12),
                          decoration: BoxDecoration(
                            color: contentTheme.danger.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: MyText.bodySmall(controller.errorMessage!,
                              color: contentTheme.danger),
                        ),
                        MySpacing.height(16),
                      ],
                      MyFlex(
                        contentPadding: false,
                        children: [
                          MyFlexItem(
                            sizes: 'lg-6 md-6',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _field('Item Name', 'e.g. Paracetamol 500mg',
                                    LucideIcons.pill, controller.nameTE),
                                MySpacing.height(20),
                                _field('Category', 'e.g. Analgesic',
                                    LucideIcons.tag, controller.categoryTE),
                                MySpacing.height(20),
                                _numericField('Price (\$)', '0.00',
                                    LucideIcons.dollar_sign, controller.priceTE,
                                    decimal: true),
                              ],
                            ),
                          ),
                          MyFlexItem(
                            sizes: 'lg-6 md-6',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _numericField('Stock (units)', '0',
                                    LucideIcons.package, controller.stockTE),
                                MySpacing.height(20),
                                _numericField('Rating (0-5)', '0.0',
                                    LucideIcons.star, controller.rateTE,
                                    decimal: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                      MySpacing.height(24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MyContainer(
                            onTap: controller.saving ? null : controller.saveItem,
                            padding: MySpacing.xy(12, 8),
                            color: contentTheme.primary,
                            borderRadiusAll: 8,
                            child: controller.saving
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: contentTheme.onPrimary),
                                  )
                                : MyText.labelMedium('Save Item',
                                    color: contentTheme.onPrimary,
                                    fontWeight: 600),
                          ),
                          MySpacing.width(12),
                          MyContainer(
                            onTap: () => Get.back(),
                            padding: MySpacing.xy(12, 8),
                            borderRadiusAll: 8,
                            color: contentTheme.secondary.withAlpha(32),
                            child: MyText.labelMedium('Cancel',
                                color: contentTheme.secondary, fontWeight: 600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field(String title, String hint, IconData icon,
      TextEditingController te) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(title, fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextFormField(
          controller: te,
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: hint,
            hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
            isCollapsed: true,
            isDense: true,
            prefixIcon: Icon(icon, size: 16),
            contentPadding: MySpacing.all(16),
          ),
        ),
      ],
    );
  }

  Widget _numericField(String title, String hint, IconData icon,
      TextEditingController te,
      {bool decimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(title, fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextFormField(
          controller: te,
          keyboardType:
              TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]')),
          ],
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: hint,
            hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
            isCollapsed: true,
            isDense: true,
            prefixIcon: Icon(icon, size: 16),
            contentPadding: MySpacing.all(16),
          ),
        ),
      ],
    );
  }
}
