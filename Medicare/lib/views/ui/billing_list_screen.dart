import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:medicare/controller/ui/billing_controller.dart';
import 'package:medicare/helpers/theme/admin_theme.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/models/invoice_model.dart';
import 'package:medicare/views/layout/layout.dart';

class BillingListScreen extends StatefulWidget {
  const BillingListScreen({super.key});

  @override
  State<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends State<BillingListScreen> with UIMixin {
  final BillingController ctrl = Get.put(BillingController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<BillingController>(
        init: ctrl,
        builder: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: MySpacing.x(flexSpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.titleMedium('Billing & Invoices',
                      fontSize: 18, fontWeight: 600),
                  Row(
                    children: [
                      MyBreadcrumb(children: [
                        MyBreadcrumbItem(name: 'Operations'),
                        MyBreadcrumbItem(name: 'Billing', active: true),
                      ]),
                      MySpacing.width(16),
                      MyButton(
                        onPressed: c.createNew,
                        elevation: 0,
                        padding: MySpacing.xy(16, 10),
                        backgroundColor: contentTheme.primary,
                        borderRadiusAll: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus,
                                size: 16, color: contentTheme.onPrimary),
                            MySpacing.width(6),
                            MyText.labelMedium('New Invoice',
                                color: contentTheme.onPrimary, fontWeight: 600),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            MySpacing.height(flexSpacing),

            // ── Stats ───────────────────────────────────────────────────────
            Padding(
              padding: MySpacing.x(flexSpacing),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _statChip('All', c.invoices.length, null, c),
                  _statChip('Pending', c.countFor('pending'),
                      Colors.orange, c),
                  _statChip(
                      'Paid', c.countFor('paid'), Colors.green, c),
                  _statChip('NHIS Claimed', c.countFor('claimed'),
                      Colors.blue, c),
                ],
              ),
            ),
            MySpacing.height(16),

            // ── Table ───────────────────────────────────────────────────────
            Padding(
              padding: MySpacing.x(flexSpacing),
              child: c.loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : c.filtered.isEmpty
                      ? MyContainer(
                          paddingAll: 40,
                          borderRadiusAll: 12,
                          child: Center(
                            child: Column(
                              children: [
                                Icon(LucideIcons.receipt,
                                    size: 40, color: Colors.grey.shade400),
                                MySpacing.height(12),
                                MyText.bodyMedium('No invoices yet',
                                    muted: true),
                              ],
                            ),
                          ),
                        )
                      : MyContainer(
                          paddingAll: 0,
                          borderRadiusAll: 12,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 24,
                              headingRowHeight: 44,
                              dataRowMinHeight: 52,
                              dataRowMaxHeight: 64,
                              columns: const [
                                DataColumn(label: Text('Invoice #')),
                                DataColumn(label: Text('Patient')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Items')),
                                DataColumn(
                                    label: Text('Subtotal'),
                                    numeric: true),
                                DataColumn(
                                    label: Text('Net Payable'),
                                    numeric: true),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('')),
                              ],
                              rows: c.filtered
                                  .map((inv) => _row(inv, c))
                                  .toList(),
                            ),
                          ),
                        ),
            ),
            MySpacing.height(flexSpacing),
          ],
        ),
      ),
    );
  }

  DataRow _row(InvoiceModel inv, BillingController c) {
    final fmt = DateFormat('dd MMM yyyy');
    return DataRow(cells: [
      DataCell(MyText.bodySmall(
          '#${inv.id.substring(0, 8).toUpperCase()}',
          fontWeight: 600)),
      DataCell(Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodySmall(inv.patientName, fontWeight: 600),
          if (inv.nhisApplied)
            MyText.bodySmall('NHIS', muted: true, fontSize: 11),
        ],
      )),
      DataCell(MyText.bodySmall(fmt.format(inv.createdAt))),
      DataCell(MyText.bodySmall('${inv.items.length} item(s)')),
      DataCell(MyText.bodySmall(
          'GHS ${inv.subtotal.toStringAsFixed(2)}',
          fontWeight: 500)),
      DataCell(MyText.bodySmall(
          'GHS ${inv.netAmount.toStringAsFixed(2)}',
          fontWeight: 700,
          color: contentTheme.primary)),
      DataCell(_statusChip(inv.status)),
      DataCell(
        MyButton(
          onPressed: () => c.openDetail(inv),
          elevation: 0,
          padding: MySpacing.xy(12, 6),
          backgroundColor: contentTheme.primary.withAlpha(20),
          borderRadiusAll: 6,
          child: MyText.labelSmall('View',
              color: contentTheme.primary, fontWeight: 600),
        ),
      ),
    ]);
  }

  Widget _statChip(
      String label, int count, Color? color, BillingController c) {
    final key = label == 'All'
        ? 'all'
        : label == 'NHIS Claimed'
            ? 'claimed'
            : label.toLowerCase();
    final selected = c.filterStatus == key;
    return InkWell(
      onTap: () => c.setFilter(key),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: MySpacing.xy(16, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? (color ?? contentTheme.primary).withAlpha(20)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? (color ?? contentTheme.primary)
                : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText.labelMedium(label,
                fontWeight: selected ? 700 : 500,
                color: selected ? (color ?? contentTheme.primary) : null),
            MySpacing.width(8),
            Container(
              padding: MySpacing.xy(6, 2),
              decoration: BoxDecoration(
                color: (color ?? contentTheme.primary).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: MyText.bodySmall('$count',
                  fontWeight: 700,
                  color: color ?? contentTheme.primary,
                  fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(InvoiceStatus status) {
    final ContentTheme ct = contentTheme;
    switch (status) {
      case InvoiceStatus.pending:
        return _chip('Pending', Colors.orange);
      case InvoiceStatus.paid:
        return _chip('Paid', Colors.green);
      case InvoiceStatus.claimed:
        return _chip('NHIS Claimed', Colors.blue);
      case InvoiceStatus.draft:
        return _chip('Draft', ct.secondary);
    }
  }

  Widget _chip(String label, Color color) => Container(
        padding: MySpacing.xy(10, 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: MyText.bodySmall(label,
            color: color, fontWeight: 600, fontSize: 11),
      );
}
