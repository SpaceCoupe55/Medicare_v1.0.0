import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/appointment_list_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/utils/utils.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_list_extension.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/images.dart';
import 'package:medicare/views/layout/layout.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> with UIMixin {
  AppointmentListController controller = Get.put(AppointmentListController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'appointment_list_controller',
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium("Appointments", fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Operations'),
                        MyBreadcrumbItem(name: 'Appointments', active: true),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyText.titleMedium("Appointment List", fontWeight: 600),
                          Row(
                            children: [
                              MyContainer(
                                onTap: controller.goToSchedulingScreen,
                                padding: MySpacing.xy(12, 8),
                                borderRadiusAll: 8,
                                color: contentTheme.primary.withAlpha(20),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.calendar_days, size: 14, color: contentTheme.primary),
                                    MySpacing.width(6),
                                    MyText.labelSmall("Schedule View", fontWeight: 600, color: contentTheme.primary),
                                  ],
                                ),
                              ),
                              MySpacing.width(12),
                              MyContainer(
                                onTap: controller.bookAppointment,
                                padding: MySpacing.xy(12, 8),
                                borderRadiusAll: 8,
                                color: contentTheme.primary,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.calendar_plus, size: 14, color: contentTheme.onPrimary),
                                    MySpacing.width(6),
                                    MyText.labelSmall("Book New", fontWeight: 600, color: contentTheme.onPrimary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      MySpacing.height(20),
                      if (controller.loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (controller.errorMessage != null)
                        _errorState(controller.errorMessage!, controller.refreshList)
                      else if (controller.appointmentListModel.isEmpty)
                        _emptyState()
                      else ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            sortAscending: true,
                            columnSpacing: 60,
                            onSelectAll: (_) => {},
                            headingRowColor: WidgetStatePropertyAll(contentTheme.primary.withAlpha(40)),
                            dataRowMaxHeight: 60,
                            showBottomBorder: true,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            border: TableBorder.all(
                              borderRadius: BorderRadius.circular(12),
                              style: BorderStyle.solid,
                              width: .4,
                              color: contentTheme.secondary,
                            ),
                            columns: [
                              DataColumn(label: MyText.labelLarge('Patient', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Consulting Doctor', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Treatment', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Mobile', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Date', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Time', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Status', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Action', color: contentTheme.primary)),
                            ],
                            rows: controller.appointmentListModel
                                .mapIndexed((index, data) => DataRow(cells: [
                                      DataCell(SizedBox(
                                        width: 200,
                                        child: Row(
                                          children: [
                                            MyContainer.rounded(
                                              height: 36,
                                              width: 36,
                                              paddingAll: 0,
                                              clipBehavior: Clip.antiAliasWithSaveLayer,
                                              child: Image.asset(Images.avatars[index % Images.avatars.length], fit: BoxFit.cover),
                                            ),
                                            MySpacing.width(12),
                                            Flexible(child: MyText.labelLarge(data.name, overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      )),
                                      DataCell(SizedBox(width: 150, child: MyText.bodySmall('Dr. ${data.consultingDoctor}', fontWeight: 600))),
                                      DataCell(MyText.bodySmall(data.treatment, fontWeight: 600)),
                                      DataCell(MyText.bodySmall(data.mobile, fontWeight: 600)),
                                      DataCell(MyText.bodySmall(Utils.getDateStringFromDateTime(data.date, showMonthShort: true), fontWeight: 600)),
                                      DataCell(MyText.bodySmall(Utils.getTimeStringFromDateTime(data.time, showSecond: false), fontWeight: 600)),
                                      DataCell(_statusChip(data.status.name)),
                                      DataCell(Row(
                                        children: [
                                          MyContainer(
                                            onTap: () => controller.goToSchedulingScreen(),
                                            paddingAll: 8,
                                            color: contentTheme.secondary.withAlpha(32),
                                            child: Icon(LucideIcons.eye, size: 16),
                                          ),
                                          MySpacing.width(8),
                                          MyContainer(
                                            onTap: () => controller.goToSchedulingEditScreen(data),
                                            paddingAll: 8,
                                            color: contentTheme.secondary.withAlpha(32),
                                            child: Icon(LucideIcons.pencil, size: 16),
                                          ),
                                          MySpacing.width(8),
                                          MyContainer(
                                            onTap: () => _confirmDelete(
                                                context,
                                                'Delete appointment for "${data.name}"?',
                                                () => controller.deleteAppointment(data.id)),
                                            paddingAll: 8,
                                            color: contentTheme.danger.withAlpha(30),
                                            child: Icon(LucideIcons.trash_2,
                                                size: 16, color: contentTheme.danger),
                                          ),
                                        ],
                                      )),
                                    ]))
                                .toList(),
                          ),
                        ),
                        if (controller.hasMore)
                          Padding(
                            padding: MySpacing.y(16),
                            child: Center(
                              child: controller.loadingMore
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : TextButton(
                                      onPressed: controller.loadMore,
                                      child: MyText.bodyMedium("Load more", color: contentTheme.primary),
                                    ),
                            ),
                          ),
                      ],
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

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = contentTheme.success;
        break;
      case 'cancelled':
        color = contentTheme.danger;
        break;
      default:
        color = contentTheme.primary;
    }
    return MyContainer(
      borderRadiusAll: 4,
      color: color.withAlpha(30),
      padding: MySpacing.xy(8, 4),
      child: MyText.bodySmall(
        status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : '',
        color: color,
        fontWeight: 600,
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
            Icon(LucideIcons.calendar_off, size: 48, color: contentTheme.secondary.withAlpha(100)),
            MySpacing.height(12),
            MyText.bodyMedium("No appointments yet", muted: true),
            MySpacing.height(12),
            MyContainer(
              onTap: controller.bookAppointment,
              borderRadiusAll: 8,
              color: contentTheme.primary.withAlpha(20),
              padding: MySpacing.xy(16, 10),
              child: MyText.bodyMedium("Book First Appointment", color: contentTheme.primary, fontWeight: 600),
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
              child: MyText.bodyMedium("Retry", color: contentTheme.primary, fontWeight: 600),
            ),
          ],
        ),
      ),
    );
  }
}
