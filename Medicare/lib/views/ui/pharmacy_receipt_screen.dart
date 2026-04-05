// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/helpers/theme/app_style.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/models/sale_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/layout/layout.dart';

String _pad(int n) => n.toString().padLeft(2, '0');
String _fmtDt(DateTime d) =>
    '${_pad(d.day)}/${_pad(d.month)}/${d.year}  ${_pad(d.hour)}:${_pad(d.minute)}';

class PharmacyReceiptScreen extends StatefulWidget {
  const PharmacyReceiptScreen({super.key});

  @override
  State<PharmacyReceiptScreen> createState() => _PharmacyReceiptScreenState();
}

class _PharmacyReceiptScreenState extends State<PharmacyReceiptScreen>
    with UIMixin {

  @override
  Widget build(BuildContext context) {
    final sale = Get.arguments as SaleModel;

    return Layout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: MySpacing.x(flexSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText.titleMedium('Sale Receipt',
                    fontSize: 18, fontWeight: 600),
                MyBreadcrumb(
                  children: [
                    MyBreadcrumbItem(name: 'Pharmacy'),
                    MyBreadcrumbItem(name: 'Receipt', active: true),
                  ],
                ),
              ],
            ),
          ),
          MySpacing.height(flexSpacing),
          Padding(
            padding: MySpacing.x(flexSpacing),
            child: MyContainer(
              borderRadiusAll: 12,
              paddingAll: 0,
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: MySpacing.all(24),
                    decoration: BoxDecoration(
                      color: contentTheme.primary,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.receipt,
                                color: contentTheme.onPrimary, size: 20),
                            MySpacing.width(10),
                            MyText.titleMedium('Receipt',
                                color: contentTheme.onPrimary, fontWeight: 700),
                          ],
                        ),
                        MySpacing.height(8),
                        MyText.bodySmall(
                          'Sale ID: ${sale.id}',
                          color: contentTheme.onPrimary.withAlpha(180),
                        ),
                        MyText.bodySmall(
                          'Date: ${_fmtDt(sale.createdAt)}',
                          color: contentTheme.onPrimary.withAlpha(180),
                        ),
                      ],
                    ),
                  ),

                  // ── Items ─────────────────────────────────────────────────
                  Padding(
                    padding: MySpacing.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText.labelLarge('Items Purchased', fontWeight: 600),
                        MySpacing.height(12),
                        // Header row
                        Row(
                          children: [
                            Expanded(
                                flex: 4,
                                child: MyText.labelMedium('Item',
                                    muted: true)),
                            Expanded(
                                child: MyText.labelMedium('Qty',
                                    muted: true,
                                    textAlign: TextAlign.center)),
                            Expanded(
                                child: MyText.labelMedium('Unit',
                                    muted: true,
                                    textAlign: TextAlign.right)),
                            Expanded(
                                child: MyText.labelMedium('Total',
                                    muted: true,
                                    textAlign: TextAlign.right)),
                          ],
                        ),
                        const Divider(height: 16),
                        for (final si in sale.items) ...[
                          Row(
                            children: [
                              Expanded(
                                  flex: 4,
                                  child: MyText.bodySmall(si.name)),
                              Expanded(
                                  child: MyText.bodySmall(
                                      '${si.quantity}',
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: MyText.bodySmall(
                                      'GHS ${si.unitPrice.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right)),
                              Expanded(
                                  child: MyText.bodySmall(
                                      'GHS ${si.lineTotal.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      fontWeight: 600)),
                            ],
                          ),
                          MySpacing.height(8),
                        ],
                        const Divider(),
                        // Grand total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MyText.titleMedium('Grand Total',
                                fontWeight: 700),
                            MyText.titleMedium(
                              'GHS ${sale.grandTotal.toStringAsFixed(2)}',
                              fontWeight: 700,
                              color: contentTheme.primary,
                            ),
                          ],
                        ),
                        MySpacing.height(24),

                        // ── Payment info ─────────────────────────────────────
                        Container(
                          padding: MySpacing.all(16),
                          decoration: BoxDecoration(
                            color: contentTheme.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText.labelLarge('Payment Details',
                                  fontWeight: 600),
                              MySpacing.height(8),
                              _detailRow('Method',
                                  sale.paymentMethod == 'cash'
                                      ? 'Cash'
                                      : 'Mobile Money'),
                              if (sale.momoPhone != null)
                                _detailRow('MoMo Phone', sale.momoPhone!),
                              if (sale.momoNetwork != null)
                                _detailRow('Network', sale.momoNetwork!),
                              if (sale.momoReference != null)
                                _detailRow(
                                    'Reference', sale.momoReference!),
                              if (sale.patientId != null)
                                _detailRow(
                                    'Patient ID', sale.patientId!),
                            ],
                          ),
                        ),

                        MySpacing.height(24),

                        // ── Actions ─────────────────────────────────────────
                        Row(
                          children: [
                            MyButton(
                              onPressed: () =>
                                  Get.offAllNamed(AppRoutes.pharmacyList),
                              elevation: 0,
                              padding: MySpacing.xy(20, 12),
                              backgroundColor: contentTheme.primary,
                              borderRadiusAll: AppStyle.buttonRadius.medium,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.plus,
                                      size: 14,
                                      color: contentTheme.onPrimary),
                                  MySpacing.width(6),
                                  MyText.labelSmall('New Sale',
                                      color: contentTheme.onPrimary,
                                      fontWeight: 600),
                                ],
                              ),
                            ),
                            MySpacing.width(12),
                            MyButton(
                              onPressed: _printReceipt,
                              elevation: 0,
                              padding: MySpacing.xy(20, 12),
                              backgroundColor:
                                  contentTheme.secondary.withAlpha(30),
                              borderRadiusAll: AppStyle.buttonRadius.medium,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.printer,
                                      size: 14,
                                      color: contentTheme.onBackground),
                                  MySpacing.width(6),
                                  MyText.labelSmall('Print Receipt',
                                      color: contentTheme.onBackground,
                                      fontWeight: 600),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          MySpacing.height(flexSpacing),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: MyText.bodySmall(label, fontWeight: 600)),
          Expanded(child: MyText.bodySmall(value, muted: true)),
        ],
      ),
    );
  }

  void _printReceipt() {
    // Triggers the browser's native print dialog on Flutter Web.
    // On non-web platforms this is a no-op.
    // ignore: undefined_prefixed_name, avoid_web_libraries_in_flutter
    try { html.window.print(); } catch (_) {}
  }
}
