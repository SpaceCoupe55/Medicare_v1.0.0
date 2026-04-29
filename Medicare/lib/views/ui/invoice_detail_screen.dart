import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:medicare/controller/ui/invoice_create_controller.dart';
import 'package:medicare/controller/ui/invoice_detail_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/models/invoice_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/layout/layout.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen>
    with UIMixin {
  final InvoiceDetailController ctrl = Get.put(InvoiceDetailController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<InvoiceDetailController>(
        init: ctrl,
        builder: (c) {
          if (c.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c.invoice == null) {
            return const Center(child: Text('Invoice not found.'));
          }
          final inv = c.invoice!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('Invoice Detail',
                        fontSize: 18, fontWeight: 600),
                    Row(
                      children: [
                        MyBreadcrumb(children: [
                          MyBreadcrumbItem(name: 'Billing',
                              route: AppRoutes.billingList),
                          MyBreadcrumbItem(name: 'Invoice', active: true),
                        ]),
                        MySpacing.width(16),
                        MyButton(
                          onPressed: () => _showPrintDialog(inv),
                          elevation: 0,
                          padding: MySpacing.xy(14, 8),
                          backgroundColor: contentTheme.primary.withAlpha(20),
                          borderRadiusAll: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.printer,
                                  size: 15, color: contentTheme.primary),
                              MySpacing.width(6),
                              MyText.labelSmall('Print',
                                  color: contentTheme.primary, fontWeight: 600),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: LayoutBuilder(builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 760;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _invoiceCard(inv)),
                        MySpacing.width(16),
                        SizedBox(width: 260, child: _actionsPanel(c, inv)),
                      ],
                    );
                  }
                  return Column(children: [
                    _invoiceCard(inv),
                    MySpacing.height(16),
                    _actionsPanel(c, inv),
                  ]);
                }),
              ),
              MySpacing.height(flexSpacing),
            ],
          );
        },
      ),
    );
  }

  // ── Invoice card ────────────────────────────────────────────────────────────

  Widget _invoiceCard(InvoiceModel inv) {
    final fmt = DateFormat('dd MMMM yyyy, h:mm a');
    return MyContainer(
      paddingAll: 24,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleMedium('INVOICE', fontWeight: 800, fontSize: 20),
                  MyText.bodySmall(
                      '#${inv.id.substring(0, 12).toUpperCase()}',
                      muted: true),
                ],
              ),
              _statusBadge(inv.status),
            ],
          ),
          const Divider(height: 28),

          // Patient & dates
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.labelSmall('Patient', muted: true, fontWeight: 600),
                    MySpacing.height(4),
                    MyText.bodyMedium(inv.patientName, fontWeight: 700),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.labelSmall('Date Issued',
                        muted: true, fontWeight: 600),
                    MySpacing.height(4),
                    MyText.bodySmall(fmt.format(inv.createdAt)),
                    if (inv.paidAt != null) ...[
                      MySpacing.height(6),
                      MyText.labelSmall('Date Paid',
                          muted: true, fontWeight: 600),
                      MySpacing.height(4),
                      MyText.bodySmall(fmt.format(inv.paidAt!)),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.labelSmall('Issued By', muted: true, fontWeight: 600),
                    MySpacing.height(4),
                    MyText.bodySmall(inv.createdBy),
                    if (inv.paymentMethod != null) ...[
                      MySpacing.height(6),
                      MyText.labelSmall('Payment',
                          muted: true, fontWeight: 600),
                      MySpacing.height(4),
                      MyText.bodySmall(_paymentLabel(inv.paymentMethod!),
                          fontWeight: 600),
                      if (inv.momoPhone != null)
                        MyText.bodySmall(
                            '${inv.momoNetwork ?? ''} · ${inv.momoPhone}',
                            muted: true,
                            fontSize: 11),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),

          // Line items table
          Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _th('Description'),
                  _th('Qty'),
                  _th('Unit Price', right: true),
                  _th('Total', right: true),
                ],
              ),
              ...inv.items.map((item) => TableRow(
                    children: [
                      _td(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.bodySmall(item.description, fontWeight: 600),
                          MyText.bodySmall(_typeLabel(item.type),
                              muted: true, fontSize: 11),
                        ],
                      )),
                      _td(MyText.bodySmall('${item.qty}')),
                      _td(MyText.bodySmall(
                          'GHS ${item.unitPrice.toStringAsFixed(2)}'),
                          right: true),
                      _td(MyText.bodySmall(
                          'GHS ${item.lineTotal.toStringAsFixed(2)}',
                          fontWeight: 600),
                          right: true),
                    ],
                  )),
            ],
          ),
          const Divider(height: 24),

          // Totals
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 260,
              child: Column(
                children: [
                  _totalRow('Subtotal',
                      'GHS ${inv.subtotal.toStringAsFixed(2)}'),
                  if (inv.nhisApplied) ...[
                    MySpacing.height(6),
                    _totalRow(
                      'NHIS (${(inv.nhisCoverage * 100).toStringAsFixed(0)}%)',
                      '- GHS ${inv.nhisAmount.toStringAsFixed(2)}',
                      color: Colors.blue,
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText.labelLarge('NET PAYABLE', fontWeight: 800),
                      MyText.labelLarge(
                        'GHS ${inv.netAmount.toStringAsFixed(2)}',
                        fontWeight: 800,
                        color: contentTheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // NHIS claim info
          if (inv.nhisApplied && inv.nhisClaimStatus != NhisClaimStatus.none)
            Padding(
              padding: MySpacing.top(20),
              child: Container(
                padding: MySpacing.xy(16, 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.shield_check,
                        size: 16, color: Colors.blue),
                    MySpacing.width(10),
                    MyText.bodySmall(
                        'NHIS Claim: ${_claimLabel(inv.nhisClaimStatus)}',
                        color: Colors.blue,
                        fontWeight: 600),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Actions panel ────────────────────────────────────────────────────────────

  Widget _actionsPanel(InvoiceDetailController c, InvoiceModel inv) {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.labelLarge('Actions', fontWeight: 700),
          MySpacing.height(16),

          if (inv.status == InvoiceStatus.pending) ...[
            _actionBtn(
              icon: LucideIcons.circle_check,
              label: 'Record Payment',
              color: Colors.green,
              onTap: () => _showPaymentDialog(c),
            ),
            MySpacing.height(10),
          ],

          if (inv.nhisApplied &&
              inv.nhisClaimStatus == NhisClaimStatus.none) ...[
            _actionBtn(
              icon: LucideIcons.send,
              label: 'Submit NHIS Claim',
              color: Colors.blue,
              onTap: c.updating ? null : c.submitNhisClaim,
            ),
            MySpacing.height(10),
          ],

          if (inv.nhisClaimStatus == NhisClaimStatus.submitted) ...[
            _actionBtn(
              icon: LucideIcons.circle_check,
              label: 'Mark Claim Approved',
              color: Colors.green,
              onTap: c.updating
                  ? null
                  : () => c.updateClaimStatus('approved'),
            ),
            MySpacing.height(6),
            _actionBtn(
              icon: LucideIcons.circle_x,
              label: 'Mark Claim Rejected',
              color: Colors.red,
              onTap: c.updating
                  ? null
                  : () => c.updateClaimStatus('rejected'),
            ),
            MySpacing.height(10),
          ],

          _actionBtn(
            icon: LucideIcons.receipt,
            label: 'All Invoices',
            color: contentTheme.primary,
            onTap: () => Get.offNamed(AppRoutes.billingList),
            outlined: true,
          ),
        ],
      ),
    );
  }

  // ── Payment dialog ───────────────────────────────────────────────────────────

  void _showPaymentDialog(InvoiceDetailController c) {
    InvoicePaymentMethod method = InvoicePaymentMethod.cash;
    InvoiceMomoNetwork network = InvoiceMomoNetwork.mtn;
    final phoneCtrl = TextEditingController();
    final refCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Record Payment'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment method:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: InvoicePaymentMethod.values
                      .map((m) => ChoiceChip(
                            label: Text(_paymentLabel(m)),
                            selected: method == m,
                            onSelected: (_) => setDlg(() => method = m),
                          ))
                      .toList(),
                ),
                if (method == InvoicePaymentMethod.momo) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<InvoiceMomoNetwork>(
                    value: network,
                    items: [
                      DropdownMenuItem(
                          value: InvoiceMomoNetwork.mtn,
                          child: const Text('MTN MoMo')),
                      DropdownMenuItem(
                          value: InvoiceMomoNetwork.vodafone,
                          child: const Text('Vodafone Cash')),
                      DropdownMenuItem(
                          value: InvoiceMomoNetwork.airteltigo,
                          child: const Text('AirtelTigo Money')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDlg(() => network = v);
                    },
                    decoration:
                        const InputDecoration(labelText: 'Network'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
                    ],
                    decoration:
                        const InputDecoration(labelText: 'Phone Number *'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: refCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Reference (optional)'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                c.recordPayment(
                  method: method,
                  momoPhone: method == InvoicePaymentMethod.momo
                      ? phoneCtrl.text.trim()
                      : null,
                  momoNetwork: method == InvoicePaymentMethod.momo
                      ? _networkLabel(network)
                      : null,
                  momoReference: method == InvoicePaymentMethod.momo
                      ? refCtrl.text.trim()
                      : null,
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrintDialog(InvoiceModel inv) {
    // On web, trigger browser print
    // ignore: avoid_web_libraries_in_flutter
    try {
      // This works in Flutter Web
      // ignore: undefined_prefixed_name
      // Use a platform channel approach; for web simply call window.print via JS
      // Fallback: show snackbar
    } catch (_) {}
    Get.snackbar('Print', 'Use Ctrl+P / Cmd+P to print this page.',
        snackPosition: SnackPosition.BOTTOM);
  }

  // ── Table helpers ────────────────────────────────────────────────────────────

  Widget _th(String text, {bool right = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(text,
            textAlign: right ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Widget _td(Widget child, {bool right = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: right
            ? Align(alignment: Alignment.centerRight, child: child)
            : child,
      );

  Widget _totalRow(String label, String value, {Color? color}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText.bodySmall(label, muted: color == null),
          MyText.bodySmall(value,
              fontWeight: 600, color: color),
        ],
      );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool outlined = false,
  }) =>
      SizedBox(
        width: double.infinity,
        child: MyButton(
          onPressed: onTap,
          elevation: 0,
          padding: MySpacing.xy(16, 11),
          backgroundColor:
              outlined ? color.withAlpha(20) : color.withAlpha(220),
          borderRadiusAll: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15, color: outlined ? color : Colors.white),
              MySpacing.width(8),
              MyText.labelSmall(label,
                  color: outlined ? color : Colors.white,
                  fontWeight: 600),
            ],
          ),
        ),
      );

  Widget _statusBadge(InvoiceStatus status) {
    Color color;
    String label;
    switch (status) {
      case InvoiceStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case InvoiceStatus.paid:
        color = Colors.green;
        label = 'Paid';
        break;
      case InvoiceStatus.claimed:
        color = Colors.blue;
        label = 'NHIS Claimed';
        break;
      case InvoiceStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        break;
    }
    return Container(
      padding: MySpacing.xy(14, 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: MyText.bodySmall(label, color: color, fontWeight: 700),
    );
  }

  String _paymentLabel(InvoicePaymentMethod m) {
    switch (m) {
      case InvoicePaymentMethod.cash:
        return 'Cash';
      case InvoicePaymentMethod.momo:
        return 'Mobile Money';
      case InvoicePaymentMethod.nhis:
        return 'NHIS Direct';
      case InvoicePaymentMethod.insurance:
        return 'Insurance';
    }
  }

  String _networkLabel(InvoiceMomoNetwork n) {
    switch (n) {
      case InvoiceMomoNetwork.vodafone:
        return 'Vodafone Cash';
      case InvoiceMomoNetwork.airteltigo:
        return 'AirtelTigo Money';
      case InvoiceMomoNetwork.mtn:
        return 'MTN MoMo';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'consultation':
        return 'Consultation';
      case 'procedure':
        return 'Procedure';
      case 'lab':
        return 'Lab Test';
      default:
        return 'Other';
    }
  }

  String _claimLabel(NhisClaimStatus s) {
    switch (s) {
      case NhisClaimStatus.submitted:
        return 'Submitted';
      case NhisClaimStatus.approved:
        return 'Approved';
      case NhisClaimStatus.rejected:
        return 'Rejected';
      default:
        return 'None';
    }
  }
}
