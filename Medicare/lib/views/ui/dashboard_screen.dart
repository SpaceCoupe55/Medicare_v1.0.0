import 'package:medicare/controller/ui/dashboard_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/utils/utils.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_list_extension.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/images.dart';
import 'package:medicare/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with UIMixin {
  DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'dashboard_controller',
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
                      "Dashboard",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Admin'),
                        MyBreadcrumbItem(name: 'Dashboard', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing / 2),
                child: MyFlex(
                  children: [
                    MyFlexItem(sizes: 'lg-3 md-6', child: stats(contentTheme.primary, LucideIcons.venetian_mask, '${controller.totalPatients}', "Total Patients")),
                    MyFlexItem(sizes: 'lg-3 md-6', child: stats(contentTheme.info, LucideIcons.stethoscope, '${controller.totalDoctors}', "Total Doctors")),
                    MyFlexItem(sizes: 'lg-3 md-6', child: stats(contentTheme.success, LucideIcons.calendar_check, '${controller.totalAppointmentsToday}', "Today's Appointments")),
                    MyFlexItem(sizes: 'lg-3 md-6', child: stats(contentTheme.warning, LucideIcons.clipboard_list, '${controller.totalAppointments}', "Total Appointments")),
                    MyFlexItem(sizes: 'lg-2 md-4', child: secondStats(LucideIcons.badge_check, "Appointments", '${controller.totalAppointments}')),
                    MyFlexItem(sizes: 'lg-2 md-4', child: secondStats(LucideIcons.badge_check, "Doctors", '${controller.totalDoctors}')),
                    MyFlexItem(sizes: 'lg-2 md-4', child: secondStats(LucideIcons.badge_check, "Patients", '${controller.totalPatients}')),
                    MyFlexItem(sizes: 'lg-2 md-4', child: secondStats(LucideIcons.badge_check, "Today", '${controller.totalAppointmentsToday}')),
                    MyFlexItem(sizes: 'lg-2 md-4', child: secondStats(LucideIcons.badge_check, "Scheduled", '${controller.totalAppointments}')),
                    MyFlexItem(sizes: 'lg-2 md-4', child: secondStats(LucideIcons.badge_check, "Completed", "—")),
                    MyFlexItem(sizes: 'lg-6', child: treatmentType()),
                    MyFlexItem(sizes: 'lg-6', child: patientByAge()),
                    MyFlexItem(sizes: 'lg-7.5', child: appointment()),
                    MyFlexItem(sizes: 'lg-4.5', child: doctorList()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget stats(Color color, IconData icon, String title, String subTitle) {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Row(
        children: [
          MyContainer.roundBordered(
            paddingAll: 8,
            borderColor: color,
            child: MyContainer.rounded(
              color: color,
              height: 44,
              width: 44,
              paddingAll: 0,
              borderRadiusAll: 8,
              child: Icon(icon, color: contentTheme.onPrimary),
            ),
          ),
          MySpacing.width(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.titleLarge(title, fontWeight: 600, overflow: TextOverflow.ellipsis),
                MyText.bodySmall(subTitle, fontWeight: 600, muted: true, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget secondStats(IconData icon, String title, String subTitle) {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      height: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyContainer.rounded(
            color: contentTheme.primary,
            height: 44,
            width: 44,
            paddingAll: 0,
            child: Icon(icon, color: contentTheme.onPrimary),
          ),
          MyText.bodySmall(title),
          MyText.titleLarge(subTitle, fontWeight: 600, xMuted: true, color: contentTheme.primary),
        ],
      ),
    );
  }

  Widget treatmentType() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Treatment Type", fontWeight: 600),
          MySpacing.height(20),
          SfCartesianChart(
            plotAreaBorderWidth: 0,
            legend: Legend(position: LegendPosition.bottom, isVisible: true),
            primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0), labelPlacement: LabelPlacement.onTicks),
            primaryYAxis: const NumericAxis(
                minimum: 30, maximum: 80, axisLine: AxisLine(width: 0), edgeLabelPlacement: EdgeLabelPlacement.shift, labelFormat: '{value}', majorTickLines: MajorTickLines(size: 0)),
            series: controller.treatmentTypeChart(),
            tooltipBehavior: TooltipBehavior(enable: true),
          )
        ],
      ),
    );
  }

  Widget patientByAge() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Patient by age", fontWeight: 600),
          MySpacing.height(20),
          SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: const CategoryAxis(
              majorGridLines: MajorGridLines(width: 0),
            ),
            primaryYAxis: const NumericAxis(maximum: 20, minimum: 0, interval: 4, axisLine: AxisLine(width: 0), majorTickLines: MajorTickLines(size: 0)),
            series: controller.patientByAgeChart(),
            legend: Legend(isVisible: true, position: LegendPosition.bottom),
            tooltipBehavior: controller.tooltipBehavior,
          )
        ],
      ),
    );
  }

  Widget appointment() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Appointment", fontWeight: 600),
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
                border: TableBorder.all(borderRadius: BorderRadius.circular(8), style: BorderStyle.solid, width: .4, color: Colors.grey),
                columns: [
                  DataColumn(label: MyText.labelLarge('Patient', color: contentTheme.primary)),
                  DataColumn(label: MyText.labelLarge('Gender', color: contentTheme.primary)),
                  DataColumn(label: MyText.labelLarge('Appointment for', color: contentTheme.primary)),
                  DataColumn(label: MyText.labelLarge('Date', color: contentTheme.primary)),
                  DataColumn(label: MyText.labelLarge('Time', color: contentTheme.primary)),
                ],
                rows: controller.appointment
                    .mapIndexed((index, data) => DataRow(cells: [
                          DataCell(SizedBox(
                            width: 200,
                            child: Row(
                              children: [
                                MyContainer.rounded(height: 36, width: 36, paddingAll: 0, clipBehavior: Clip.antiAliasWithSaveLayer, child: Image.asset(Images.avatars[index % Images.avatars.length])),
                                MySpacing.width(20),
                                MyText.labelLarge(data['patient_name'], overflow: TextOverflow.ellipsis, maxLines: 1),
                              ],
                            ),
                          )),
                          DataCell(MyText.bodySmall(data['gender'], fontWeight: 600)),
                          DataCell(SizedBox(width: 200, child: MyText.bodySmall("Dr. ${data['appointment_for']}", fontWeight: 600))),
                          DataCell(SizedBox(width: 100, child: MyText.bodySmall(Utils.getDateStringFromDateTime(data['date'], showMonthShort: true), fontWeight: 600))),
                          DataCell(SizedBox(width: 100, child: MyText.bodySmall(Utils.getTimeStringFromDateTime(data['time'], showSecond: false), fontWeight: 600))),
                        ]))
                    .toList()),
          ),
        ],
      ),
    );
  }

  Widget doctorList() {
    Widget doctorDetail(String image, String doctorName, String professionalization) {
      return Padding(
        padding: MySpacing.x(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyContainer.rounded(
              height: 44,
              width: 44,
              paddingAll: 0,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Image.asset(image, fit: BoxFit.cover),
            ),
            MySpacing.width(20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleMedium("Dr. $doctorName", fontWeight: 600),
                  MyText.bodySmall(professionalization, muted: true),
                ],
              ),
            ),
            Row(
              children: [
                Icon(Icons.circle_rounded, size: 8, color: contentTheme.success),
                MySpacing.width(8),
                MyText.bodyMedium("Available", fontWeight: 600, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      );
    }

    final docs = controller.topDoctors;
    return MyContainer(
      borderRadiusAll: 12,
      paddingAll: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: MySpacing.all(20),
            child: MyText.titleMedium("Doctor List", fontWeight: 600),
          ),
          if (docs.isEmpty)
            Padding(
              padding: MySpacing.all(20),
              child: MyText.bodySmall('No doctors added yet.', muted: true),
            )
          else
            ...docs.asMap().entries.expand((entry) {
              final i = entry.key;
              final d = entry.value;
              return [
                doctorDetail(
                  Images.avatars[i % Images.avatars.length],
                  d['name'] as String? ?? '',
                  d['designation'] as String? ?? '',
                ),
                if (i < docs.length - 1) const Divider(height: 33),
              ];
            }),
          MySpacing.height(20),
        ],
      ),
    );
  }
}
