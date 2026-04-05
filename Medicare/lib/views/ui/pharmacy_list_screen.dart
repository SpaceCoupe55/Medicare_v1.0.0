import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/cart_controller.dart';
import 'package:medicare/controller/ui/pharmacy_list_controller.dart';
import 'package:medicare/helpers/theme/app_style.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/models/pharmacy_model.dart';
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
      child: GetBuilder<PharmacyListController>(
        init: controller,
        tag: 'pharmacy_list_controller',
        builder: (ctrl) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Breadcrumb ───────────────────────────────────────────────
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary bar ────────────────────────────────────────
                    if (!ctrl.loading)
                      Row(
                        children: [
                          _SummaryCard(
                            icon: LucideIcons.package,
                            label: 'Total Items',
                            value: '${ctrl.totalItemCount}',
                            color: contentTheme.primary,
                          ),
                          MySpacing.width(16),
                          _SummaryCard(
                            icon: LucideIcons.circle_dollar_sign,
                            label: 'Inventory Value',
                            value:
                                'GHS ${ctrl.totalInventoryValue.toStringAsFixed(2)}',
                            color: const Color(0xFF26A69A),
                          ),
                        ],
                      ),
                    MySpacing.height(16),

                    // ── Toolbar ────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MyText.bodyMedium('All Items',
                            fontWeight: 600, muted: true),
                        Row(
                          children: [
                            // Cart button with badge
                            Obx(() {
                              final count =
                                  CartController.instance.totalItems;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  MyContainer(
                                    onTap: ctrl.goToCart,
                                    padding: MySpacing.xy(12, 8),
                                    borderRadiusAll: 8,
                                    color: contentTheme.primary
                                        .withAlpha(20),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.shopping_cart,
                                            size: 14,
                                            color: contentTheme.primary),
                                        MySpacing.width(6),
                                        MyText.labelSmall('Cart',
                                            fontWeight: 600,
                                            color: contentTheme.primary),
                                      ],
                                    ),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$count',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }),
                            if (ctrl.isAdmin) ...[
                              MySpacing.width(10),
                              MyContainer(
                                onTap: ctrl.goToAdd,
                                padding: MySpacing.xy(12, 8),
                                borderRadiusAll: 8,
                                color: contentTheme.primary,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.plus,
                                        size: 14,
                                        color: contentTheme.onPrimary),
                                    MySpacing.width(6),
                                    MyText.labelSmall('Add Item',
                                        fontWeight: 600,
                                        color: contentTheme.onPrimary),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    MySpacing.height(16),

                    // ── Search bar ─────────────────────────────────────────
                    _SearchBar(
                      controller: ctrl.searchTE,
                      hint: 'Search by name or category…',
                      onChanged: ctrl.onSearchChanged,
                      onClear: ctrl.clearSearch,
                    ),
                    MySpacing.height(12),

                    // ── Category chips ─────────────────────────────────────
                    if (ctrl.categoryOptions.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: ctrl.categoryFilter == null,
                            onTap: () => ctrl.setCategoryFilter(null),
                          ),
                          for (final c in ctrl.categoryOptions)
                            _FilterChip(
                              label: c,
                              selected: ctrl.categoryFilter == c,
                              onTap: () => ctrl.setCategoryFilter(c),
                            ),
                        ],
                      ),
                    MySpacing.height(10),

                    // ── Result count ───────────────────────────────────────
                    if (!ctrl.loading)
                      MyText.bodySmall(
                        'Showing ${ctrl.displayItems.length} of '
                        '${ctrl.totalItemCount} items',
                        muted: true,
                      ),
                    MySpacing.height(16),

                    // ── Grid / states ──────────────────────────────────────
                    if (ctrl.loading)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(60),
                              child: CircularProgressIndicator()))
                    else if (ctrl.errorMessage != null)
                      _errorState(ctrl.errorMessage!, ctrl.refreshList)
                    else if (ctrl.displayItems.isEmpty)
                      _emptyState(ctrl)
                    else ...[
                      MyFlex(
                        children: [
                          MyFlexItem(
                            child: GridView.builder(
                              shrinkWrap: true,
                              primary: true,
                              itemCount: ctrl.displayItems.length,
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 340,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 280,
                              ),
                              itemBuilder: (_, idx) =>
                                  _ItemCard(
                                item: ctrl.displayItems[idx],
                                isAdmin: ctrl.isAdmin,
                                onEdit: () =>
                                    ctrl.goToEdit(ctrl.displayItems[idx]),
                                onDelete: () => _confirmDelete(
                                  context,
                                  'Delete "${ctrl.displayItems[idx].name}"?',
                                  () => ctrl.deleteItem(
                                      ctrl.displayItems[idx].id),
                                ),
                                onAddToCart: (qty) => ctrl.addToCart(
                                    ctrl.displayItems[idx], qty),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ctrl.hasMore)
                        Padding(
                          padding: MySpacing.y(16),
                          child: Center(
                            child: ctrl.loadingMore
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : TextButton(
                                    onPressed: ctrl.loadMore,
                                    child: MyText.bodyMedium('Load more',
                                        color: contentTheme.primary),
                                  ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext ctx, String msg, VoidCallback onConfirm) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: Text('Delete',
                style: TextStyle(color: contentTheme.danger)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(PharmacyListController ctrl) => Center(
        child: Padding(
          padding: MySpacing.y(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.package_x,
                  size: 48,
                  color: contentTheme.secondary.withAlpha(100)),
              MySpacing.height(12),
              MyText.bodyMedium('No items match your search', muted: true),
            ],
          ),
        ),
      );

  Widget _errorState(String msg, VoidCallback onRetry) => Center(
        child: Padding(
          padding: MySpacing.y(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.circle_alert,
                  size: 48, color: contentTheme.danger),
              MySpacing.height(12),
              MyText.bodyMedium(msg,
                  muted: true, textAlign: TextAlign.center),
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

// ── Summary card ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget with UIMixin {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            MySpacing.width(14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.bodySmall(label, muted: true),
                MyText.titleMedium(value, fontWeight: 700, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item card ──────────────────────────────────────────────────────────────

class _ItemCard extends StatefulWidget {
  final PharmacyModel item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(int qty) onAddToCart;

  const _ItemCard({
    required this.item,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onAddToCart,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> with UIMixin {
  int _qty = 1;

  Color get _stockColor {
    if (widget.item.stock == 0) return const Color(0xFFD32F2F);
    if (widget.item.stock <= 10) return const Color(0xFFF57C00);
    return const Color(0xFF388E3C);
  }

  String get _stockLabel {
    if (widget.item.stock == 0) return 'Out of stock';
    if (widget.item.stock <= 10) return 'Low stock';
    return 'In stock';
  }

  @override
  Widget build(BuildContext context) {
    final outOfStock = widget.item.stock == 0;

    return MyContainer(
      paddingAll: 16,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: name + admin actions ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MyText.bodyMedium(widget.item.name,
                    fontWeight: 600,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2),
              ),
              if (widget.isAdmin) ...[
                MySpacing.width(4),
                InkWell(
                  onTap: widget.onEdit,
                  child: Icon(LucideIcons.pencil,
                      size: 14, color: theme.hintColor),
                ),
                MySpacing.width(8),
                InkWell(
                  onTap: widget.onDelete,
                  child: Icon(LucideIcons.trash_2,
                      size: 14, color: contentTheme.danger),
                ),
              ],
            ],
          ),
          MySpacing.height(6),

          // ── Category ──────────────────────────────────────────────────
          MyText.bodySmall(widget.item.category, muted: true),
          MySpacing.height(8),

          // ── Price + stock badge ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.bodyMedium(
                  'GHS ${widget.item.price.toStringAsFixed(2)}',
                  fontWeight: 700),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _stockColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _stockLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _stockColor,
                  ),
                ),
              ),
            ],
          ),
          MySpacing.height(4),
          MyText.bodySmall('${widget.item.stock} units', muted: true),

          const Spacer(),

          // ── Qty selector + add to cart ─────────────────────────────────
          if (!outOfStock) ...[
            Row(
              children: [
                _qtyBtn(LucideIcons.minus,
                    () => setState(() => _qty = (_qty - 1).clamp(1, widget.item.stock))),
                MySpacing.width(8),
                Container(
                  width: 32,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: contentTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: MyText.bodySmall('$_qty',
                      color: contentTheme.onPrimary, fontWeight: 600),
                ),
                MySpacing.width(8),
                _qtyBtn(LucideIcons.plus,
                    () => setState(() => _qty = (_qty + 1).clamp(1, widget.item.stock))),
              ],
            ),
            MySpacing.height(8),
          ],
          MyButton(
            onPressed: outOfStock
                ? null
                : () => widget.onAddToCart(_qty),
            elevation: 0,
            padding: MySpacing.xy(12, 8),
            borderRadiusAll: AppStyle.buttonRadius.medium,
            backgroundColor: outOfStock
                ? contentTheme.secondary.withAlpha(30)
                : contentTheme.primary,
            block: true,
            child: MyText.labelSmall(
              outOfStock ? 'Out of stock' : 'Add to cart',
              color: outOfStock
                  ? contentTheme.secondary
                  : contentTheme.onPrimary,
              fontWeight: 600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: contentTheme.secondary.withAlpha(80)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14),
        ),
      );
}

// ── Shared search / filter widgets ────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
        prefixIcon:
            Icon(LucideIcons.search, size: 16, color: theme.hintColor),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, v, __) => v.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: Icon(LucideIcons.x,
                      size: 15, color: theme.hintColor),
                  onPressed: onClear,
                ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: theme.colorScheme.onSurface.withAlpha(60)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: theme.colorScheme.onSurface.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primary : primary.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? primary : primary.withAlpha(60)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : primary,
          ),
        ),
      ),
    );
  }
}
