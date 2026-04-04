import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/pharmacy_list_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_star_rating.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/views/layout/layout.dart';

class PharmacyListScreen extends StatefulWidget {
  const PharmacyListScreen({super.key});

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> with UIMixin {
  PharmacyListController controller = Get.put(PharmacyListController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'pharmacy_list_controller',
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('Pharmacy Inventory',
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Operations'),
                        MyBreadcrumbItem(name: 'Pharmacy', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.bodyMedium('All Items', fontWeight: 600, muted: true),
                    MyContainer(
                      onTap: controller.goToAdd,
                      padding: MySpacing.xy(12, 8),
                      borderRadiusAll: 8,
                      color: contentTheme.primary,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, size: 14, color: contentTheme.onPrimary),
                          MySpacing.width(6),
                          MyText.labelSmall('Add Item',
                              fontWeight: 600, color: contentTheme.onPrimary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              MySpacing.height(16),
              if (controller.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (controller.errorMessage != null)
                _errorState(controller.errorMessage!, controller.refreshList)
              else if (controller.products.isEmpty)
                _emptyState()
              else ...[
                Padding(
                  padding: MySpacing.x(flexSpacing / 2),
                  child: MyFlex(
                    children: [
                      MyFlexItem(
                        child: GridView.builder(
                          shrinkWrap: true,
                          primary: true,
                          itemCount: controller.products.length,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            mainAxisExtent: 320,
                          ),
                          itemBuilder: (context, index) {
                            final product = controller.products[index];
                            final id = product['id'] as String? ?? '';
                            return MyContainer(
                              paddingAll: 16,
                              borderRadiusAll: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row: name + delete button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: MyText.bodyMedium(
                                            product['name'] ?? '',
                                            fontWeight: 600,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      MyContainer(
                                        onTap: () => _confirmDelete(
                                            context,
                                            'Delete "${product['name']}"?',
                                            () => controller.deleteItem(id)),
                                        paddingAll: 6,
                                        color: contentTheme.danger.withAlpha(30),
                                        borderRadiusAll: 6,
                                        child: Icon(LucideIcons.trash_2,
                                            size: 14, color: contentTheme.danger),
                                      ),
                                    ],
                                  ),
                                  MySpacing.height(8),
                                  MyText.bodySmall(
                                      'Category: ${product['category'] ?? '—'}',
                                      muted: true),
                                  MySpacing.height(4),
                                  MyText.bodySmall(
                                      'Stock: ${product['stock'] ?? 0} units',
                                      muted: true),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      MyText.bodyMedium(
                                          '\$${product['price']}.00',
                                          fontWeight: 600),
                                      MyStarRating(
                                        rating: (product['rate'] as num?)
                                                ?.toDouble() ??
                                            0.0,
                                        activeColor: contentTheme.warning,
                                      ),
                                    ],
                                  ),
                                  MySpacing.height(8),
                                  MyContainer(
                                    onTap: () => controller.goToDetails(id),
                                    width: double.infinity,
                                    padding: MySpacing.xy(12, 8),
                                    borderRadiusAll: 8,
                                    color: contentTheme.primary.withAlpha(20),
                                    child: Center(
                                      child: MyText.labelSmall('View Details',
                                          color: contentTheme.primary,
                                          fontWeight: 600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.hasMore)
                  Padding(
                    padding: MySpacing.y(16),
                    child: Center(
                      child: controller.loadingMore
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : TextButton(
                              onPressed: controller.loadMore,
                              child: MyText.bodyMedium('Load more',
                                  color: contentTheme.primary),
                            ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: Text('Delete', style: TextStyle(color: contentTheme.danger)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: MySpacing.y(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.package_x, size: 48,
                color: contentTheme.secondary.withAlpha(100)),
            MySpacing.height(12),
            MyText.bodyMedium('No items in inventory', muted: true),
            MySpacing.height(12),
            MyContainer(
              onTap: controller.goToAdd,
              borderRadiusAll: 8,
              color: contentTheme.primary.withAlpha(20),
              padding: MySpacing.xy(16, 10),
              child: MyText.bodyMedium('Add First Item',
                  color: contentTheme.primary, fontWeight: 600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: MySpacing.y(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circle_alert, size: 48, color: contentTheme.danger),
            MySpacing.height(12),
            MyText.bodyMedium(message, muted: true, textAlign: TextAlign.center),
            MySpacing.height(12),
            MyContainer(
              onTap: onRetry,
              borderRadiusAll: 8,
              color: contentTheme.primary.withAlpha(20),
              padding: MySpacing.xy(16, 10),
              child: MyText.bodyMedium('Retry',
                  color: contentTheme.primary, fontWeight: 600),
            ),
          ],
        ),
      ),
    );
  }
}
