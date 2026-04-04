import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
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
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium("Dashboard", fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Home'),
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
                    // ── Stat cards ─────────────────────────────────────────
                    MyFlexItem(
                      sizes: 'lg-3 md-6',
                      child: _statCard(
                        color: contentTheme.primary,
                        icon: LucideIcons.venetian_mask,
                        value: '${controller.totalPatients}',
                        label: "Total Patients",
                        onTap: controller.goToPatients,
                      ),
                    ),
                    MyFlexItem(
                      sizes: 'lg-3 md-6',
                      child: _statCard(
                        color: contentTheme.info,
                        icon: LucideIcons.stethoscope,
                        value: '${controller.totalDoctors}',
                        label: "Total Doctors",
                        onTap: controller.goToDoctors,
                      ),
                    ),
                    MyFlexItem(
                      sizes: 'lg-3 md-6',
                      child: _statCard(
                        color: contentTheme.success,
                        icon: LucideIcons.calendar_check,
                        value: '${controller.totalAppointmentsToday}',
                        label: "Today's Appointments",
                        onTap: controller.goToAppointments,
                      ),
                    ),
                    MyFlexItem(
                      sizes: 'lg-3 md-6',
                      child: _statCard(
                        color: contentTheme.warning,
                        icon: LucideIcons.clipboard_list,
                        value: '${controller.totalAppointments}',
                        label: "Total Appointments",
                        onTap: controller.goToAppointments,
                      ),
                    ),

                    // ── Quick actions ──────────────────────────────────────
                    MyFlexItem(sizes: 'lg-12', child: _quickActions()),

                    // ── Charts ─────────────────────────────────────────────
                    MyFlexItem(sizes: 'lg-6', child: _appointmentChart()),
                    MyFlexItem(sizes: 'lg-6', child: _patientChart()),

                    // ── Recent appointments + top doctors ──────────────────
                    MyFlexItem(sizes: 'lg-7.5', child: _recentAppointments()),
                    MyFlexItem(sizes: 'lg-4.5', child: _doctorList()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Stat card (tappable) ──────────────────────────────────────────────────

  Widget _statCard({
    required Color color,
    required IconData icon,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return MyContainer(
      onTap: onTap,
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
                MyText.titleLarge(value, fontWeight: 600, overflow: TextOverflow.ellipsis),
                MyText.bodySmall(label, fontWeight: 600, muted: true, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(LucideIcons.chevron_right, size: 16, color: color.withAlpha(160)),
        ],
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _quickActions() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Quick Actions", fontWeight: 600),
          MySpacing.height(16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionButton(
                icon: LucideIcons.user_plus,
                label: "New Patient",
                onTap: controller.goToAddPatient,
              ),
              _actionButton(
                icon: LucideIcons.calendar_plus,
                label: "Book Appointment",
                onTap: controller.goToBookAppointment,
              ),
              if (controller.isAdmin)
                _actionButton(
                  icon: LucideIcons.briefcase_medical,
                  label: "Add Doctor",
                  onTap: controller.goToAddDoctor,
                ),
              if (controller.isAdmin)
                _actionButton(
                  icon: LucideIcons.chart_bar,
                  label: "View Reports",
                  onTap: controller.goToReports,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return MyContainer(
      onTap: onTap,
      borderRadiusAll: 8,
      color: contentTheme.primary.withAlpha(20),
      padding: MySpacing.xy(16, 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: contentTheme.primary),
          MySpacing.width(8),
          MyText.bodyMedium(label, color: contentTheme.primary, fontWeight: 600),
        ],
      ),
    );
  }

  // ── Charts ────────────────────────────────────────────────────────────────

  Widget _appointmentChart() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Appointments (This Year)", fontWeight: 600),
          MySpacing.height(20),
          SfCartesianChart(
            plotAreaBorderWidth: 0,
            legend: Legend(position: LegendPosition.bottom, isVisible: true),
            primaryXAxis: const CategoryAxis(
              majorGridLines: MajorGridLines(width: 0),
              labelPlacement: LabelPlacement.onTicks,
            ),
            primaryYAxis: const NumericAxis(
              minimum: 0,
              axisLine: AxisLine(width: 0),
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              majorTickLines: MajorTickLines(size: 0),
            ),
            series: controller.treatmentTypeChart(),
            tooltipBehavior: TooltipBehavior(enable: true),
          ),
        ],
      ),
    );
  }

  Widget _patientChart() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Patient Registrations by Gender", fontWeight: 600),
          MySpacing.height(20),
          SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: const CategoryAxis(
              majorGridLines: MajorGridLines(width: 0),
            ),
            primaryYAxis: const NumericAxis(
              minimum: 0,
              axisLine: AxisLine(width: 0),
              majorTickLines: MajorTickLines(size: 0),
            ),
            series: controller.patientByAgeChart(),
            legend: Legend(isVisible: true, position: LegendPosition.bottom),
            tooltipBehavior: controller.tooltipBehavior,
          ),
        ],
      ),
    );
  }

  // ── Recent appointments ───────────────────────────────────────────────────

  Widget _recentAppointments() {
    final appts = controller.recentAppointments;
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.titleMedium("Recent Appointments", fontWeight: 600),
              MyContainer(
                onTap: controller.goToAppointments,
                borderRadiusAll: 6,
                color: contentTheme.primary.withAlpha(20),
                padding: MySpacing.xy(10, 6),
                child: MyText.bodySmall("View All", color: contentTheme.primary, fontWeight: 600),
              ),
            ],
          ),
          MySpacing.height(16),
          if (appts.isEmpty)
            Padding(
              padding: MySpacing.y(24),
              child: Center(
                child: MyText.bodySmall("No appointments yet", muted: true),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortAscending: true,
                columnSpacing: 40,
                onSelectAll: (_) => {},
                headingRowColor: WidgetStatePropertyAll(contentTheme.primary.withAlpha(40)),
                dataRowMaxHeight: 56,
                showBottomBorder: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                border: TableBorder.all(
                  borderRadius: BorderRadius.circular(8),
                  style: BorderStyle.solid,
                  width: .4,
                  color: Colors.grey,
                ),
                columns: [
                  DataColumn(label: MyText.labelLarge('Patient', color: contentTheme.primary)),
                  DataColumn(label: MyText.labelLarge('Doctor', color: contentTheme.primary)),
                  DataColumn(label: MyText.labelLarge('Date', color: contentTheme.primary)),
                  DataColumn(label: MyText.labelLarge('Status', color: contentTheme.primary)),
                ],
                rows: appts
                    .mapIndexed((index, data) => DataRow(
                          onSelectChanged: (_) => controller.goToAppointmentDetail(data['id'] as String),
                          cells: [
                            DataCell(Row(
                              children: [
                                MyContainer.rounded(
                                  height: 32,
                                  width: 32,
                                  paddingAll: 0,
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  child: Image.asset(Images.avatars[index % Images.avatars.length]),
                                ),
                                MySpacing.width(12),
                                SizedBox(
                                  width: 140,
                                  child: MyText.labelLarge(
                                    data['patient_name'] as String? ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )),
                            DataCell(SizedBox(
                              width: 140,
                              child: MyText.bodySmall(
                                "Dr. ${data['appointment_for'] ?? ''}",
                                fontWeight: 600,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                            DataCell(MyText.bodySmall(
                              Utils.getDateStringFromDateTime(data['date'] as DateTime, showMonthShort: true),
                              fontWeight: 600,
                            )),
                            DataCell(_statusChip(data['status'] as String? ?? 'scheduled')),
                          ],
                        ))
                    .toList(),
              ),
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
        status[0].toUpperCase() + status.substring(1),
        color: color,
        fontWeight: 600,
      ),
    );
  }

  // ── Top doctors ───────────────────────────────────────────────────────────

  Widget _doctorList() {
    Widget doctorRow(String image, String name, String specialization) {
      return Padding(
        padding: MySpacing.x(20),
        child: Row(
          children: [
            MyContainer.rounded(
              height: 44,
              width: 44,
              paddingAll: 0,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Image.asset(image, fit: BoxFit.cover),
            ),
            MySpacing.width(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleMedium("Dr. $name", fontWeight: 600),
                  MyText.bodySmall(specialization, muted: true),
                ],
              ),
            ),
            Row(
              children: [
                Icon(Icons.circle_rounded, size: 8, color: contentTheme.success),
                MySpacing.width(6),
                MyText.bodySmall("Active", fontWeight: 600),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText.titleMedium("Top Doctors", fontWeight: 600),
                MyContainer(
                  onTap: controller.goToDoctors,
                  borderRadiusAll: 6,
                  color: contentTheme.primary.withAlpha(20),
                  padding: MySpacing.xy(10, 6),
                  child: MyText.bodySmall("View All", color: contentTheme.primary, fontWeight: 600),
                ),
              ],
            ),
          ),
          if (docs.isEmpty)
            Padding(
              padding: MySpacing.fromLTRB(20, 0, 20, 20),
              child: MyText.bodySmall('No doctors added yet.', muted: true),
            )
          else
            ...docs.asMap().entries.expand((entry) {
              final i = entry.key;
              final d = entry.value;
              return [
                doctorRow(
                  Images.avatars[i % Images.avatars.length],
                  d['name'] as String? ?? '',
                  d['designation'] as String? ?? '',
                ),
                if (i < docs.length - 1) const Divider(height: 28),
              ];
            }),
          MySpacing.height(20),
        ],
      ),
    );
  }
}
