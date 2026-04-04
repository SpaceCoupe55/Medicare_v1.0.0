import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/reports_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/views/layout/layout.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with UIMixin {
  ReportsController controller = Get.put(ReportsController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'reports_controller',
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium("Reports & Analytics", fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Home'),
                        MyBreadcrumbItem(name: 'Reports', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),

              if (controller.loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.errorMessage != null)
                _errorState(controller.errorMessage!)
              else
                Padding(
                  padding: MySpacing.x(flexSpacing / 2),
                  child: MyFlex(
                    children: [
                      // ── Row 1: Appointment trend + Status donut ──────────
                      MyFlexItem(sizes: 'lg-8', child: _appointmentTrend()),
                      MyFlexItem(sizes: 'lg-4', child: _statusDonut()),

                      // ── Row 2: Patient growth + Blood group ──────────────
                      MyFlexItem(sizes: 'lg-6', child: _patientGrowth()),
                      MyFlexItem(sizes: 'lg-6', child: _bloodGroup()),

                      // ── Row 3: Doctors by specialization (full width) ────
                      MyFlexItem(sizes: 'lg-12', child: _specialization()),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: MySpacing.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circle_alert, size: 48, color: contentTheme.danger),
            MySpacing.height(16),
            MyText.bodyMedium(message, muted: true, textAlign: TextAlign.center),
            MySpacing.height(16),
            MyContainer(
              onTap: controller.loadData,
              borderRadiusAll: 8,
              color: contentTheme.primary,
              paddingAll: 12,
              child: MyText.bodyMedium("Retry", color: contentTheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chart widgets ──────────────────────────────────────────────────────────

  Widget _appointmentTrend() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Monthly Appointments", fontWeight: 600),
          MySpacing.height(20),
          SfCartesianChart(
            plotAreaBorderWidth: 0,
            legend: Legend(isVisible: true, position: LegendPosition.bottom),
            primaryXAxis: const CategoryAxis(
              majorGridLines: MajorGridLines(width: 0),
              labelPlacement: LabelPlacement.onTicks,
            ),
            primaryYAxis: const NumericAxis(
              minimum: 0,
              axisLine: AxisLine(width: 0),
              majorTickLines: MajorTickLines(size: 0),
            ),
            series: controller.appointmentTrendSeries(),
            tooltipBehavior: controller.tooltipBehavior,
          ),
        ],
      ),
    );
  }

  Widget _statusDonut() {
    final data = controller.statusDonutData();
    final total = controller.scheduledCount + controller.completedCount + controller.cancelledCount;
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Appointment Status", fontWeight: 600),
          MySpacing.height(20),
          SfCircularChart(
            legend: Legend(isVisible: true, position: LegendPosition.bottom),
            tooltipBehavior: controller.tooltipBehavior,
            annotations: [
              CircularChartAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText.titleLarge('$total', fontWeight: 700),
                    MyText.bodySmall('Total', muted: true),
                  ],
                ),
              ),
            ],
            series: <CircularSeries>[
              DoughnutSeries<dynamic, String>(
                dataSource: data,
                xValueMapper: (d, _) => d.x as String,
                yValueMapper: (d, _) => d.y,
                pointColorMapper: (d, _) => d.pointColor,
                innerRadius: '60%',
                dataLabelSettings: const DataLabelSettings(isVisible: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patientGrowth() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Patient Registrations (This Year)", fontWeight: 600),
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
            series: controller.patientGrowthSeries(),
            tooltipBehavior: controller.tooltipBehavior,
          ),
        ],
      ),
    );
  }

  Widget _bloodGroup() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Patients by Blood Type", fontWeight: 600),
          MySpacing.height(20),
          controller.bloodGroupData.isEmpty
              ? Padding(
                  padding: MySpacing.y(24),
                  child: Center(
                    child: MyText.bodySmall('No blood type data available', muted: true),
                  ),
                )
              : SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: const CategoryAxis(
                    majorGridLines: MajorGridLines(width: 0),
                  ),
                  primaryYAxis: const NumericAxis(
                    minimum: 0,
                    axisLine: AxisLine(width: 0),
                    majorTickLines: MajorTickLines(size: 0),
                  ),
                  series: controller.bloodGroupSeries(),
                  tooltipBehavior: controller.tooltipBehavior,
                ),
        ],
      ),
    );
  }

  Widget _specialization() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Doctors by Specialization", fontWeight: 600),
          MySpacing.height(20),
          controller.specializationData.isEmpty
              ? Padding(
                  padding: MySpacing.y(24),
                  child: Center(
                    child: MyText.bodySmall('No specialization data available', muted: true),
                  ),
                )
              : SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: const CategoryAxis(
                    majorGridLines: MajorGridLines(width: 0),
                    labelIntersectAction: AxisLabelIntersectAction.rotate45,
                  ),
                  primaryYAxis: const NumericAxis(
                    minimum: 0,
                    axisLine: AxisLine(width: 0),
                    majorTickLines: MajorTickLines(size: 0),
                  ),
                  series: controller.specializationSeries(),
                  tooltipBehavior: controller.tooltipBehavior,
                ),
        ],
      ),
    );
  }
}
