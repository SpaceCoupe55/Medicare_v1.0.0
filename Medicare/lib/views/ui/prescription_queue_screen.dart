import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:medicare/controller/ui/prescription_queue_controller.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/models/prescription_model.dart';
import 'package:medicare/views/layout/layout.dart';

class PrescriptionQueueScreen extends StatefulWidget {
  const PrescriptionQueueScreen({super.key});

  @override
  State<PrescriptionQueueScreen> createState() =>
      _PrescriptionQueueScreenState();
}

class _PrescriptionQueueScreenState extends State<PrescriptionQueueScreen>
    with UIMixin {
  final PrescriptionQueueController controller =
      Get.put(PrescriptionQueueController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<PrescriptionQueueController>(
        init: controller,
        tag: 'prescription_queue_controller',
        builder: (ctrl) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('Prescription Queue',
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Pharmacy'),
                        MyBreadcrumbItem(
                            name: 'Rx Queue', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),

              // ── Body ────────────────────────────────────────────────────────
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: MyContainer(
                  paddingAll: 20,
                  borderRadiusAll: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toolbar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _tabChip(
                                label:
                                    'Pending (${ctrl.pending.length})',
                                active: !ctrl.showFulfilled,
                                onTap: () {
                                  if (ctrl.showFulfilled) ctrl.toggleView();
                                },
                              ),
                              MySpacing.width(8),
                              _tabChip(
                                label:
                                    'Fulfilled (${ctrl.fulfilled.length})',
                                active: ctrl.showFulfilled,
                                onTap: () {
                                  if (!ctrl.showFulfilled) ctrl.toggleView();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      MySpacing.height(20),

                      if (ctrl.loading)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(),
                        ))
                      else if (ctrl.displayed.isEmpty)
                        _emptyState(ctrl.showFulfilled)
                      else
                        _table(ctrl),
                    ],
                  ),
                ),
              ),
              MySpacing.height(flexSpacing),
            ],
          );
        },
      ),
    );
  }

  // ── Tab chip ────────────────────────────────────────────────────────────────

  Widget _tabChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: MySpacing.xy(14, 8),
        decoration: BoxDecoration(
          color: active
              ? contentTheme.primary
              : contentTheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: MyText(
          label,
          style: MyTextStyle.bodySmall(
            color: active ? contentTheme.onPrimary : contentTheme.primary,
            fontWeight: 600,
          ),
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _emptyState(bool fulfilled) {
    return Center(
      child: Padding(
        padding: MySpacing.y(40),
        child: Column(
          children: [
            Icon(
              fulfilled ? LucideIcons.circle_check : LucideIcons.clipboard_list,
              size: 48,
              color: theme.hintColor,
            ),
            MySpacing.height(12),
            MyText.bodyLarge(
              fulfilled
                  ? 'No fulfilled prescriptions yet.'
                  : 'No pending prescriptions.',
              muted: true,
            ),
            if (!fulfilled) ...[
              MySpacing.height(6),
              MyText.bodySmall(
                'Prescriptions written by doctors will appear here.',
                muted: true,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Table ───────────────────────────────────────────────────────────────────

  Widget _table(PrescriptionQueueController ctrl) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
            contentTheme.primary.withAlpha(12)),
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Patient')),
          DataColumn(label: Text('Doctor')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Medicines')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: ctrl.displayed.map((rx) => _row(rx, ctrl)).toList(),
      ),
    );
  }

  DataRow _row(PrescriptionModel rx, PrescriptionQueueController ctrl) {
    final isPending = rx.status == PrescriptionStatus.pending;
    final statusColor =
        isPending ? contentTheme.warning : contentTheme.success;
    final statusLabel = isPending ? 'Pending' : 'Fulfilled';
    final dateStr = DateFormat('MMM d, yyyy').format(rx.createdAt);

    return DataRow(cells: [
      // Patient
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MyText.bodySmall(rx.patientName, fontWeight: 600),
        ],
      )),

      // Doctor
      DataCell(MyText.bodySmall(rx.doctorName, muted: true)),

      // Date
      DataCell(MyText.bodySmall(dateStr, muted: true)),

      // Medicines
      DataCell(
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...rx.items.take(3).map((item) {
                final name = item['name'] as String? ?? '—';
                final dosage = item['dosage'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(LucideIcons.pill, size: 11,
                          color: contentTheme.primary),
                      MySpacing.width(4),
                      Flexible(
                        child: MyText.bodySmall(
                          dosage.isNotEmpty ? '$name · $dosage' : name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (rx.items.length > 3)
                MyText.bodySmall(
                  '+${rx.items.length - 3} more',
                  muted: true,
                  fontSize: 11,
                ),
            ],
          ),
        ),
      ),

      // Status chip
      DataCell(Container(
        padding: MySpacing.xy(8, 4),
        decoration: BoxDecoration(
          color: statusColor.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: MyText(
          statusLabel,
          style: MyTextStyle.bodySmall(
            color: statusColor,
            fontWeight: 600,
            fontSize: 11,
          ),
        ),
      )),

      // Action
      DataCell(isPending
          ? MyButton(
              onPressed: () => ctrl.fulfillPrescription(rx),
              padding: MySpacing.xy(12, 6),
              backgroundColor: contentTheme.primary,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.shopping_cart,
                      size: 13, color: contentTheme.onPrimary),
                  MySpacing.width(5),
                  MyText(
                    'Fulfill',
                    style: MyTextStyle.bodySmall(
                        color: contentTheme.onPrimary, fontWeight: 600),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Icon(LucideIcons.circle_check,
                    size: 14, color: contentTheme.success),
                MySpacing.width(4),
                MyText.bodySmall(
                  rx.fulfilledAt != null
                      ? DateFormat('MMM d').format(rx.fulfilledAt!)
                      : 'Done',
                  muted: true,
                ),
              ],
            )),
    ]);
  }
}
