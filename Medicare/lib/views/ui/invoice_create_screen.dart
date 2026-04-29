import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/invoice_create_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/views/layout/layout.dart';

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen>
    with UIMixin {
  final InvoiceCreateController ctrl = Get.put(InvoiceCreateController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<InvoiceCreateController>(
        init: ctrl,
        builder: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: MySpacing.x(flexSpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.titleMedium('New Invoice',
                      fontSize: 18, fontWeight: 600),
                  MyBreadcrumb(children: [
                    MyBreadcrumbItem(name: 'Billing'),
                    MyBreadcrumbItem(name: 'Create', active: true),
                  ]),
                ],
              ),
            ),
            MySpacing.height(flexSpacing),
            Padding(
              padding: MySpacing.x(flexSpacing),
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 760;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _mainPanel(c)),
                      MySpacing.width(16),
                      SizedBox(width: 280, child: _summaryPanel(c)),
                    ],
                  );
                }
                return Column(children: [
                  _mainPanel(c),
                  MySpacing.height(16),
                  _summaryPanel(c),
                ]);
              }),
            ),
            MySpacing.height(flexSpacing),
          ],
        ),
      ),
    );
  }

  // ── Main left panel ─────────────────────────────────────────────────────────

  Widget _mainPanel(InvoiceCreateController c) {
    return Column(
      children: [
        // Patient
        MyContainer(
          paddingAll: 20,
          borderRadiusAll: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(LucideIcons.user, 'Patient'),
              MySpacing.height(12),
              c.loadingPatients
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: c.selectedPatient?.id,
                      decoration: _inputDecoration('Select patient'),
                      items: [
                        DropdownMenuItem<String>(
                            value: null,
                            child: MyText.bodySmall('-- Select patient --',
                                muted: true)),
                        ...c.patients.map((p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: MyText.bodySmall(
                                  '${p.name}  ·  ${p.mobileNumber}',
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (id) {
                        final patient =
                            c.patients.firstWhereOrNull((p) => p.id == id);
                        c.selectPatient(patient);
                      },
                    ),
            ],
          ),
        ),
        MySpacing.height(16),

        // Line items
        MyContainer(
          paddingAll: 20,
          borderRadiusAll: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionHeader(LucideIcons.list, 'Line Items'),
                  MyButton(
                    onPressed: c.addLineItem,
                    elevation: 0,
                    padding: MySpacing.xy(12, 6),
                    backgroundColor: contentTheme.primary.withAlpha(20),
                    borderRadiusAll: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus,
                            size: 14, color: contentTheme.primary),
                        MySpacing.width(4),
                        MyText.labelSmall('Add Item',
                            color: contentTheme.primary, fontWeight: 600),
                      ],
                    ),
                  ),
                ],
              ),
              MySpacing.height(16),
              ...List.generate(c.lineItems.length,
                  (i) => _lineItemRow(c, i)),
            ],
          ),
        ),
        MySpacing.height(16),

        // NHIS
        MyContainer(
          paddingAll: 20,
          borderRadiusAll: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(LucideIcons.shield_check, 'Insurance / NHIS'),
              MySpacing.height(12),
              Obx(() => Row(
                    children: [
                      Switch(
                        value: c.nhisApplied.value,
                        activeColor: contentTheme.primary,
                        onChanged: (v) => c.nhisApplied.value = v,
                      ),
                      MySpacing.width(8),
                      MyText.bodySmall('Apply NHIS coverage'),
                    ],
                  )),
              Obx(() {
                if (!c.nhisApplied.value) return const SizedBox.shrink();
                return Padding(
                  padding: MySpacing.top(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText.labelSmall('Coverage %',
                                fontWeight: 600, muted: true),
                            MySpacing.height(6),
                            TextFormField(
                              controller: c.nhisCoverageCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'))
                              ],
                              style: MyTextStyle.bodySmall(),
                              decoration: _inputDecoration('e.g. 50'),
                              onChanged: (_) => c.update(),
                            ),
                          ],
                        ),
                      ),
                      MySpacing.width(16),
                      Expanded(
                        child: MyContainer(
                          paddingAll: 12,
                          borderRadiusAll: 8,
                          color: Colors.blue.withAlpha(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText.labelSmall('NHIS covers',
                                  color: Colors.blue, fontWeight: 600),
                              Obx(() => MyText.bodyMedium(
                                    'GHS ${c.nhisAmount.toStringAsFixed(2)}',
                                    fontWeight: 700,
                                    color: Colors.blue,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        MySpacing.height(16),

        // Payment method (shown always — for "Save & Mark Paid")
        MyContainer(
          paddingAll: 20,
          borderRadiusAll: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                  LucideIcons.credit_card, 'Payment Method (if paying now)'),
              MySpacing.height(12),
              Obx(() => Wrap(
                    spacing: 10,
                    children: InvoicePayMethod.values
                        .map((m) => _methodChip(c, m))
                        .toList(),
                  )),
              Obx(() {
                if (c.paymentMethod.value != InvoicePayMethod.momo) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MySpacing.height(16),
                    MyText.labelSmall('Network', fontWeight: 600, muted: true),
                    MySpacing.height(6),
                    Obx(() => DropdownButtonFormField<InvoiceMomoNetwork>(
                          value: c.momoNetwork.value,
                          decoration: _inputDecoration(''),
                          items: const [
                            DropdownMenuItem(
                                value: InvoiceMomoNetwork.mtn,
                                child: Text('MTN MoMo')),
                            DropdownMenuItem(
                                value: InvoiceMomoNetwork.vodafone,
                                child: Text('Vodafone Cash')),
                            DropdownMenuItem(
                                value: InvoiceMomoNetwork.airteltigo,
                                child: Text('AirtelTigo Money')),
                          ],
                          onChanged: (v) {
                            if (v != null) c.setMomoNetwork(v);
                          },
                        )),
                    MySpacing.height(12),
                    MyText.labelSmall('Phone Number *',
                        fontWeight: 600, muted: true),
                    MySpacing.height(6),
                    TextFormField(
                      controller: c.momoPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
                      ],
                      style: MyTextStyle.bodySmall(),
                      decoration: _inputDecoration('024 000 0000'),
                    ),
                    MySpacing.height(12),
                    MyText.labelSmall('Reference (optional)',
                        fontWeight: 600, muted: true),
                    MySpacing.height(6),
                    TextFormField(
                      controller: c.momoReferenceCtrl,
                      style: MyTextStyle.bodySmall(),
                      decoration: _inputDecoration('Transaction ref'),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lineItemRow(InvoiceCreateController c, int index) {
    final item = c.lineItems[index];
    return Padding(
      padding: MySpacing.bottom(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MyText.labelSmall('Item ${index + 1}',
                  muted: true, fontWeight: 600),
              const Spacer(),
              if (c.lineItems.length > 1)
                InkWell(
                  onTap: () => c.removeLineItem(index),
                  child: Icon(LucideIcons.trash_2,
                      size: 15, color: Colors.red.shade400),
                ),
            ],
          ),
          MySpacing.height(6),
          Row(
            children: [
              // Description
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: item.descCtrl,
                  style: MyTextStyle.bodySmall(),
                  decoration: _inputDecoration('Description'),
                  onChanged: (_) => c.update(),
                ),
              ),
              MySpacing.width(8),
              // Type
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<String>(
                  value: item.type,
                  decoration: _inputDecoration('Type'),
                  items: InvoiceCreateController.itemTypes
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t),
                              style: MyTextStyle.bodySmall())))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) c.setItemType(index, v);
                  },
                ),
              ),
              MySpacing.width(8),
              // Price
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: item.priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  style: MyTextStyle.bodySmall(),
                  decoration: _inputDecoration('Price'),
                  onChanged: (_) => c.update(),
                ),
              ),
              MySpacing.width(8),
              // Qty
              SizedBox(
                width: 64,
                child: TextFormField(
                  controller: item.qtyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  style: MyTextStyle.bodySmall(),
                  decoration: _inputDecoration('Qty'),
                  onChanged: (_) => c.update(),
                ),
              ),
            ],
          ),
          if (item.lineTotal > 0)
            Padding(
              padding: MySpacing.top(4),
              child: MyText.bodySmall(
                  '= GHS ${item.lineTotal.toStringAsFixed(2)}',
                  muted: true,
                  fontSize: 11),
            ),
          if (index < c.lineItems.length - 1)
            Divider(height: 20, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  // ── Summary right panel ─────────────────────────────────────────────────────

  Widget _summaryPanel(InvoiceCreateController c) {
    return Column(
      children: [
        MyContainer(
          paddingAll: 20,
          borderRadiusAll: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(LucideIcons.receipt, 'Summary'),
              MySpacing.height(16),
              Obx(() {
                return Column(
                  children: [
                    // Line item breakdown
                    ...c.lineItems
                        .where((i) =>
                            i.descCtrl.text.trim().isNotEmpty &&
                            i.lineTotal > 0)
                        .map((i) => Padding(
                              padding: MySpacing.bottom(6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: MyText.bodySmall(
                                      i.descCtrl.text.trim(),
                                      overflow: TextOverflow.ellipsis,
                                      muted: true,
                                    ),
                                  ),
                                  MyText.bodySmall(
                                    'GHS ${i.lineTotal.toStringAsFixed(2)}',
                                    fontWeight: 500,
                                  ),
                                ],
                              ),
                            )),
                    const Divider(height: 20),
                    _summaryRow('Subtotal',
                        'GHS ${c.subtotal.toStringAsFixed(2)}'),
                    if (c.nhisApplied.value) ...[
                      MySpacing.height(4),
                      _summaryRow(
                        'NHIS (${(c.nhisCoverageFraction * 100).toStringAsFixed(0)}%)',
                        '- GHS ${c.nhisAmount.toStringAsFixed(2)}',
                        color: Colors.blue,
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MyText.titleSmall('Net Payable',
                            fontWeight: 700),
                        MyText.titleSmall(
                          'GHS ${c.netAmount.toStringAsFixed(2)}',
                          fontWeight: 700,
                          color: contentTheme.primary,
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        MySpacing.height(12),
        // Save pending
        SizedBox(
          width: double.infinity,
          child: MyButton(
            onPressed: c.saving ? null : () => c.save(markPaid: false),
            elevation: 0,
            padding: MySpacing.xy(16, 13),
            backgroundColor: contentTheme.primary.withAlpha(25),
            borderRadiusAll: 10,
            child: c.saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : MyText.labelMedium('Save as Pending',
                    color: contentTheme.primary, fontWeight: 600),
          ),
        ),
        MySpacing.height(8),
        // Save & mark paid
        SizedBox(
          width: double.infinity,
          child: MyButton(
            onPressed: c.saving ? null : () => c.save(markPaid: true),
            elevation: 0,
            padding: MySpacing.xy(16, 13),
            backgroundColor: contentTheme.primary,
            borderRadiusAll: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.circle_check,
                    size: 16, color: contentTheme.onPrimary),
                MySpacing.width(8),
                MyText.labelMedium('Save & Mark Paid',
                    color: contentTheme.onPrimary, fontWeight: 600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 16, color: contentTheme.primary),
          MySpacing.width(8),
          MyText.labelLarge(title, fontWeight: 600),
        ],
      );

  Widget _summaryRow(String label, String value, {Color? color}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText.bodySmall(label, muted: color == null),
          MyText.bodySmall(value,
              fontWeight: 600, color: color),
        ],
      );

  Widget _methodChip(InvoiceCreateController c, InvoicePayMethod m) {
    final label = _methodLabel(m);
    return Obx(() {
      final selected = c.paymentMethod.value == m;
      return InkWell(
        onTap: () => c.setPaymentMethod(m),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: MySpacing.xy(14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? contentTheme.primary
                  : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? contentTheme.primary.withAlpha(15)
                : Colors.transparent,
          ),
          child: MyText.labelSmall(label,
              fontWeight: selected ? 700 : 500,
              color: selected ? contentTheme.primary : null),
        ),
      );
    });
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: MySpacing.all(14),
        isDense: true,
        isCollapsed: true,
        hintText: hint,
        hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
      );

  String _typeLabel(String type) {
    switch (type) {
      case 'consultation':
        return 'Consult.';
      case 'procedure':
        return 'Procedure';
      case 'lab':
        return 'Lab';
      default:
        return 'Other';
    }
  }

  String _methodLabel(InvoicePayMethod m) {
    switch (m) {
      case InvoicePayMethod.cash:
        return 'Cash';
      case InvoicePayMethod.momo:
        return 'Mobile Money';
      case InvoicePayMethod.nhis:
        return 'NHIS Direct';
      case InvoicePayMethod.insurance:
        return 'Insurance';
    }
  }
}
