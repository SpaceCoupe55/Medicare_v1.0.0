import 'package:flutter_lucide/flutter_lucide.dart';
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                    MyText.titleMedium(
                      "Appointment List",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Admin'),
                        MyBreadcrumbItem(name: 'Appointment List', active: true),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.titleMedium("Appointments", fontWeight: 600),
                          MyContainer(
                            onTap: controller.bookAppointment,
                            padding: MySpacing.xy(12, 8),
                            borderRadiusAll: 8,
                            color: contentTheme.primary,
                            child: MyText.labelSmall("Add Appointment", fontWeight: 600, color: contentTheme.onPrimary),
                          )
                        ],
                      ),
                      MySpacing.height(20),
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
                                borderRadius: BorderRadius.circular(12), style: BorderStyle.solid, width: .4, color: contentTheme.secondary),
                            columns: [
                              DataColumn(label: MyText.labelLarge('Name', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Consulting Doctor', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Treatment', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Mobile', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Email', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Date', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Time', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelLarge('Action', color: contentTheme.primary)),
                            ],
                            rows: controller.appointmentListModel
                                .mapIndexed((index, data) => DataRow(cells: [
                                      DataCell(SizedBox(
                                        width: 250,
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
                                            MyText.labelLarge(data.name),
                                          ],
                                        ),
                                      )),
                                      DataCell(SizedBox(width: 150, child: MyText.bodySmall('Dr. ${data.consultingDoctor}', fontWeight: 600))),
                                      DataCell(MyText.bodySmall(data.treatment, fontWeight: 600)),
                                      DataCell(MyText.bodySmall(data.mobile, fontWeight: 600)),
                                      DataCell(SizedBox(width: 250, child: MyText.bodySmall(data.email, fontWeight: 600))),
                                      DataCell(MyText.bodySmall(Utils.getDateStringFromDateTime(data.date, showMonthShort: true), fontWeight: 600)),
                                      DataCell(MyText.bodySmall(Utils.getTimeStringFromDateTime(data.time, showSecond: false), fontWeight: 600)),
                                      DataCell(Row(
                                        children: [
                                          MyContainer(
                                            onTap: controller.goToSchedulingScreen,
                                            paddingAll: 8,
                                            color: contentTheme.secondary.withAlpha(32),
                                            child: Icon(LucideIcons.eye, size: 16),
                                          ),
                                          MySpacing.width(20),
                                          MyContainer(
                                            onTap: controller.goToSchedulingEditScreen,
                                            paddingAll: 8,
                                            color: contentTheme.secondary.withAlpha(32),
                                            child: Icon(LucideIcons.pencil, size: 16),
                                          ),
                                        ],
                                      )),
                                    ]))
                                .toList()),
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
}
