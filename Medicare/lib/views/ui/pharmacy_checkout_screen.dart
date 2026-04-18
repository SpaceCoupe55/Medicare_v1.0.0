import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/cart_controller.dart';
import 'package:medicare/controller/ui/pharmacy_checkout_controller.dart';
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

class PharmacyCheckoutScreen extends StatefulWidget {
  const PharmacyCheckoutScreen({super.key});

  @override
  State<PharmacyCheckoutScreen> createState() => _PharmacyCheckoutScreenState();
}

class _PharmacyCheckoutScreenState extends State<PharmacyCheckoutScreen>
    with UIMixin {
  final PharmacyCheckoutController controller =
      Get.put(PharmacyCheckoutController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<PharmacyCheckoutController>(
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
                    MyText.titleMedium('Checkout',
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Pharmacy'),
                        MyBreadcrumbItem(name: 'Checkout', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),

              // Prescription fulfillment banner
              if (c.activePrescription != null)
                Padding(
                  padding: MySpacing.x(flexSpacing),
                  child: Container(
                    margin: MySpacing.bottom(flexSpacing),
                    padding: MySpacing.xy(16, 12),
                    decoration: BoxDecoration(
                      color: contentTheme.primary.withAlpha(18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: contentTheme.primary.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.file_check,
                            size: 18, color: contentTheme.primary),
                        MySpacing.width(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText.bodyMedium(
                                'Filling prescription for ${c.activePrescription!.patientName}',
                                fontWeight: 700,
                                color: contentTheme.primary,
                              ),
                              MyText.bodySmall(
                                'By ${c.activePrescription!.doctorName} · '
                                '${c.activePrescription!.items.length} medicine(s) pre-loaded in cart',
                                muted: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: MySpacing.x(flexSpacing),
                child: LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 720;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _paymentPanel(c)),
                        MySpacing.width(16),
                        SizedBox(width: 300, child: _orderPanel(c)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _paymentPanel(c),
                      MySpacing.height(16),
                      _orderPanel(c),
                    ],
                  );
                }),
              ),
              MySpacing.height(flexSpacing),
            ],
          );
        },
      ),
    );
  }

  // ── Payment / Patient panel ─────────────────────────────────────────────────

  Widget _paymentPanel(PharmacyCheckoutController c) {
    return MyContainer(
      paddingAll: 24,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Patient (optional) ────────────────────────────────────────────
          _sectionHeader(LucideIcons.user, 'Patient (Optional)'),
          MySpacing.height(12),
          c.loadingPatients
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: c.selectedPatient?.id,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: MySpacing.all(16),
                    isDense: true,
                    isCollapsed: true,
                    hintText: 'Select patient (optional)',
                    hintStyle:
                        MyTextStyle.bodySmall(fontWeight: 600, muted: true),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                        value: null,
                        child: MyText.bodySmall('-- Walk-in / No patient --',
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

          MySpacing.height(24),

          // ── Payment method ────────────────────────────────────────────────
          _sectionHeader(LucideIcons.credit_card, 'Payment Method'),
          MySpacing.height(12),
          Obx(() => Row(
                children: [
                  _radioOption(
                    label: 'Cash',
                    icon: LucideIcons.banknote,
                    selected:
                        c.paymentMethod.value == PaymentMethod.cash,
                    onTap: () => c.setPaymentMethod(PaymentMethod.cash),
                  ),
                  MySpacing.width(12),
                  _radioOption(
                    label: 'Mobile Money',
                    icon: LucideIcons.smartphone,
                    selected:
                        c.paymentMethod.value == PaymentMethod.momo,
                    onTap: () => c.setPaymentMethod(PaymentMethod.momo),
                  ),
                ],
              )),

          // ── MoMo fields ───────────────────────────────────────────────────
          Obx(() {
            if (c.paymentMethod.value != PaymentMethod.momo) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MySpacing.height(20),
                _sectionHeader(LucideIcons.smartphone, 'Mobile Money Details'),
                MySpacing.height(12),

                // Network dropdown
                MyText.labelMedium('Network', fontWeight: 600, muted: true),
                MySpacing.height(8),
                Obx(() => DropdownButtonFormField<MomoNetwork>(
                      value: c.momoNetwork.value,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: MySpacing.all(16),
                        isDense: true,
                        isCollapsed: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: MomoNetwork.mtn,
                            child: Text('MTN MoMo')),
                        DropdownMenuItem(
                            value: MomoNetwork.vodafone,
                            child: Text('Vodafone Cash')),
                        DropdownMenuItem(
                            value: MomoNetwork.airteltigo,
                            child: Text('AirtelTigo Money')),
                      ],
                      onChanged: (v) {
                        if (v != null) c.setMomoNetwork(v);
                      },
                    )),

                MySpacing.height(16),

                // Phone number
                MyText.labelMedium('Phone Number *',
                    fontWeight: 600, muted: true),
                MySpacing.height(8),
                TextFormField(
                  controller: c.momoPhoneTE,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
                  ],
                  style: MyTextStyle.bodySmall(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    hintText: '024 000 0000',
                    hintStyle:
                        MyTextStyle.bodySmall(fontWeight: 600, muted: true),
                    isDense: true,
                    isCollapsed: true,
                    prefixIcon:
                        const Icon(LucideIcons.phone, size: 16),
                    contentPadding: MySpacing.all(16),
                  ),
                ),

                MySpacing.height(16),

                // Reference (optional)
                MyText.labelMedium('Transaction Reference (optional)',
                    fontWeight: 600, muted: true),
                MySpacing.height(8),
                TextFormField(
                  controller: c.momoReferenceTE,
                  style: MyTextStyle.bodySmall(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    hintText: 'e.g. 123456789',
                    hintStyle:
                        MyTextStyle.bodySmall(fontWeight: 600, muted: true),
                    isDense: true,
                    isCollapsed: true,
                    prefixIcon:
                        const Icon(LucideIcons.hash, size: 16),
                    contentPadding: MySpacing.all(16),
                  ),
                ),
              ],
            );
          }),

          MySpacing.height(28),

          // ── Complete Sale button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: MyButton(
              onPressed: c.completing ? null : c.completeSale,
              elevation: 0,
              padding: MySpacing.xy(20, 14),
              backgroundColor: contentTheme.primary,
              borderRadiusAll: 10,
              child: c.completing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: contentTheme.onPrimary),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.circle_check,
                            size: 16, color: contentTheme.onPrimary),
                        MySpacing.width(8),
                        MyText.labelMedium('Complete Sale',
                            color: contentTheme.onPrimary, fontWeight: 600),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Order summary panel ─────────────────────────────────────────────────────

  Widget _orderPanel(PharmacyCheckoutController c) {
    final cart = CartController.instance;
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(LucideIcons.receipt, 'Order Summary'),
              MySpacing.height(16),
              ...cart.items.map((ci) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText.bodySmall(ci.item.name,
                                  fontWeight: 600,
                                  overflow: TextOverflow.ellipsis),
                              MyText.bodySmall(
                                  '${ci.quantity.value} × GHS ${ci.item.price.toStringAsFixed(2)}',
                                  muted: true,
                                  fontSize: 11),
                            ],
                          ),
                        ),
                        MyText.bodySmall(
                            'GHS ${ci.lineTotal.toStringAsFixed(2)}',
                            fontWeight: 600),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.titleMedium('Grand Total', fontWeight: 700),
                  MyText.titleMedium(
                    'GHS ${cart.subtotal.toStringAsFixed(2)}',
                    fontWeight: 700,
                    color: contentTheme.primary,
                  ),
                ],
              ),
            ],
          )),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: contentTheme.primary),
        MySpacing.width(8),
        MyText.labelLarge(title, fontWeight: 600),
      ],
    );
  }

  Widget _radioOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: MySpacing.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? contentTheme.primary
                  : contentTheme.secondary.withAlpha(80),
              width: selected ? 2 : 1,
            ),
            color: selected
                ? contentTheme.primary.withAlpha(15)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? contentTheme.primary
                      : contentTheme.onBackground),
              MySpacing.width(8),
              MyText.labelMedium(label,
                  fontWeight: selected ? 700 : 500,
                  color: selected ? contentTheme.primary : null),
            ],
          ),
        ),
      ),
    );
  }
}
