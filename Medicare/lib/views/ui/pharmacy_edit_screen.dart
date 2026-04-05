import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/pharmacy_add_controller.dart';
import 'package:medicare/controller/ui/pharmacy_edit_controller.dart';
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

class PharmacyEditScreen extends StatefulWidget {
  const PharmacyEditScreen({super.key});

  @override
  State<PharmacyEditScreen> createState() => _PharmacyEditScreenState();
}

class _PharmacyEditScreenState extends State<PharmacyEditScreen> with UIMixin {
  PharmacyEditController controller = Get.put(PharmacyEditController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<PharmacyEditController>(
        init: controller,
        builder: (c) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('Edit Pharmacy Item',
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Pharmacy'),
                        MyBreadcrumbItem(name: 'Edit Item', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: MyContainer(
                  paddingAll: 24,
                  borderRadiusAll: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText.titleMedium('Item Details', fontWeight: 600),
                      MySpacing.height(20),
                      if (c.errorMessage != null) ...[
                        Container(
                          padding: MySpacing.all(12),
                          decoration: BoxDecoration(
                            color: contentTheme.danger.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: MyText.bodySmall(c.errorMessage!,
                              color: contentTheme.danger),
                        ),
                        MySpacing.height(16),
                      ],
                      MyFlex(
                        contentPadding: false,
                        children: [
                          // ── Left column ──────────────────────────────────
                          MyFlexItem(
                            sizes: 'lg-6 md-12',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _textField('Item Name', 'e.g. Paracetamol 500mg',
                                    LucideIcons.pill, c.nameTE),
                                MySpacing.height(20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MyText.labelMedium('Category',
                                        fontWeight: 600, muted: true),
                                    MySpacing.height(8),
                                    DropdownButtonFormField<String>(
                                      value: c.selectedCategory,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        contentPadding: MySpacing.all(16),
                                        isDense: true,
                                        isCollapsed: true,
                                        prefixIcon: const Icon(
                                            LucideIcons.tag,
                                            size: 16),
                                      ),
                                      items: kPharmacyCategories
                                          .map((cat) => DropdownMenuItem(
                                              value: cat,
                                              child: MyText.bodySmall(cat)))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) c.setCategory(v);
                                      },
                                    ),
                                  ],
                                ),
                                MySpacing.height(20),
                                _numericField('Price (GHS)', '0.00',
                                    LucideIcons.circle_dollar_sign, c.priceTE,
                                    decimal: true),
                              ],
                            ),
                          ),
                          // ── Right column ─────────────────────────────────
                          MyFlexItem(
                            sizes: 'lg-6 md-12',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _numericField('Stock (units)', '0',
                                    LucideIcons.package, c.stockTE),
                                MySpacing.height(20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MyText.labelMedium('Description',
                                        fontWeight: 600, muted: true),
                                    MySpacing.height(8),
                                    TextFormField(
                                      controller: c.descriptionTE,
                                      maxLines: 5,
                                      style: MyTextStyle.bodySmall(),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        hintText:
                                            'Optional notes about this item…',
                                        hintStyle: MyTextStyle.bodySmall(
                                            fontWeight: 600, muted: true),
                                        contentPadding: MySpacing.all(16),
                                        isDense: true,
                                        isCollapsed: true,
                                      ),
                                    ),
                                  ],
                                ),
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
                            onTap: c.saving ? null : c.saveItem,
                            padding: MySpacing.xy(20, 10),
                            color: contentTheme.primary,
                            borderRadiusAll: 8,
                            child: c.saving
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: contentTheme.onPrimary),
                                  )
                                : MyText.labelMedium('Save Changes',
                                    color: contentTheme.onPrimary,
                                    fontWeight: 600),
                          ),
                          MySpacing.width(12),
                          MyContainer(
                            onTap: () => Get.back(),
                            padding: MySpacing.xy(20, 10),
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

  Widget _textField(String label, String hint, IconData icon,
      TextEditingController te) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(label, fontWeight: 600, muted: true),
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

  Widget _numericField(String label, String hint, IconData icon,
      TextEditingController te,
      {bool decimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(label, fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextFormField(
          controller: te,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
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
