import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/appointment_list_controller.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
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
import 'package:medicare/models/appointment_model.dart';
import 'package:medicare/views/layout/layout.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with UIMixin {
  AppointmentListController controller =
      Get.put(AppointmentListController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<AppointmentListController>(
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
                    MyText.titleMedium("Appointments",
                        fontSize: 18, fontWeight: 600),
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
                      // ── Toolbar ──────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyText.titleMedium("Appointment List",
                              fontWeight: 600),
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
                                    Icon(LucideIcons.calendar_days,
                                        size: 14, color: contentTheme.primary),
                                    MySpacing.width(6),
                                    MyText.labelSmall("Schedule View",
                                        fontWeight: 600,
                                        color: contentTheme.primary),
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
                                    Icon(LucideIcons.calendar_plus,
                                        size: 14,
                                        color: contentTheme.onPrimary),
                                    MySpacing.width(6),
                                    MyText.labelSmall("Book New",
                                        fontWeight: 600,
                                        color: contentTheme.onPrimary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      MySpacing.height(16),

                      // ── Search bar ───────────────────────────────────────
                      _SearchBar(
                        controller: controller.searchTE,
                        hint:
                            'Search by patient, doctor, date (dd/mm/yyyy)…',
                        onChanged: controller.onSearchChanged,
                        onClear: controller.clearSearch,
                      ),
                      MySpacing.height(12),

                      // ── Status chips ─────────────────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: controller.statusFilter == null,
                            onTap: () => controller.setStatusFilter(null),
                          ),
                          _FilterChip(
                            label: 'Scheduled',
                            selected: controller.statusFilter ==
                                AppointmentStatus.scheduled,
                            onTap: () => controller.setStatusFilter(
                                AppointmentStatus.scheduled),
                          ),
                          _FilterChip(
                            label: 'Completed',
                            selected: controller.statusFilter ==
                                AppointmentStatus.completed,
                            onTap: () => controller.setStatusFilter(
                                AppointmentStatus.completed),
                          ),
                          _FilterChip(
                            label: 'Cancelled',
                            selected: controller.statusFilter ==
                                AppointmentStatus.cancelled,
                            onTap: () => controller.setStatusFilter(
                                AppointmentStatus.cancelled),
                          ),
                        ],
                      ),
                      MySpacing.height(12),

                      // ── Date range ───────────────────────────────────────
                      _DateRangeRow(
                        fromDate: controller.fromDate,
                        toDate: controller.toDate,
                        onFromTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: controller.fromDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          controller.setFromDate(d);
                        },
                        onToTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: controller.toDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          controller.setToDate(d);
                        },
                        onClear: controller.clearDateRange,
                      ),
                      MySpacing.height(10),

                      // ── Result count ─────────────────────────────────────
                      if (!controller.loading)
                        MyText.bodySmall(
                          'Showing ${controller.appointmentListModel.length} of '
                          '${controller.totalCount} appointments',
                          muted: true,
                        ),
                      MySpacing.height(16),

                      // ── Table / states ───────────────────────────────────
                      if (controller.loading)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator()))
                      else if (controller.errorMessage != null)
                        _errorState(
                            controller.errorMessage!, controller.refreshList)
                      else if (controller.appointmentListModel.isEmpty)
                        _emptyState()
                      else ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            sortAscending: true,
                            columnSpacing: 60,
                            onSelectAll: (_) {},
                            headingRowColor: WidgetStatePropertyAll(
                                contentTheme.primary.withAlpha(40)),
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
                                .mapIndexed(
                                    (index, data) => DataRow(cells: [
                                          DataCell(SizedBox(
                                            width: 200,
                                            child: Row(
                                              children: [
                                                MyContainer.rounded(
                                                  height: 36,
                                                  width: 36,
                                                  paddingAll: 0,
                                                  clipBehavior: Clip
                                                      .antiAliasWithSaveLayer,
                                                  child: Image.asset(
                                                      Images.avatars[index %
                                                          Images.avatars
                                                              .length],
                                                      fit: BoxFit.cover),
                                                ),
                                                MySpacing.width(12),
                                                Flexible(
                                                    child: MyText.labelLarge(
                                                        data.name,
                                                        overflow: TextOverflow
                                                            .ellipsis)),
                                              ],
                                            ),
                                          )),
                                          DataCell(SizedBox(
                                              width: 150,
                                              child: MyText.bodySmall(
                                                  'Dr. ${data.consultingDoctor}',
                                                  fontWeight: 600))),
                                          DataCell(MyText.bodySmall(
                                              data.treatment,
                                              fontWeight: 600)),
                                          DataCell(MyText.bodySmall(
                                              data.mobile,
                                              fontWeight: 600)),
                                          DataCell(MyText.bodySmall(
                                              Utils.getDateStringFromDateTime(
                                                  data.date,
                                                  showMonthShort: true),
                                              fontWeight: 600)),
                                          DataCell(MyText.bodySmall(
                                              Utils.getTimeStringFromDateTime(
                                                  data.time,
                                                  showSecond: false),
                                              fontWeight: 600)),
                                          DataCell(
                                              _statusChip(data.status.name)),
                                          DataCell(Row(
                                            children: [
                                              MyContainer(
                                                onTap: () => controller
                                                    .goToSchedulingScreen(),
                                                paddingAll: 8,
                                                color: contentTheme.secondary
                                                    .withAlpha(32),
                                                child: Icon(LucideIcons.eye,
                                                    size: 16),
                                              ),
                                              MySpacing.width(8),
                                              MyContainer(
                                                onTap: () => controller
                                                    .goToSchedulingEditScreen(
                                                        data),
                                                paddingAll: 8,
                                                color: contentTheme.secondary
                                                    .withAlpha(32),
                                                child: Icon(
                                                    LucideIcons.pencil,
                                                    size: 16),
                                              ),
                                              MySpacing.width(8),
                                              MyContainer(
                                                onTap: () => _confirmDelete(
                                                  context,
                                                  'Delete appointment for "${data.name}"?',
                                                  () => controller
                                                      .deleteAppointment(
                                                          data.id),
                                                ),
                                                paddingAll: 8,
                                                color: contentTheme.danger
                                                    .withAlpha(30),
                                                child: Icon(
                                                    LucideIcons.trash_2,
                                                    size: 16,
                                                    color:
                                                        contentTheme.danger),
                                              ),
                                              if (data.status ==
                                                  AppointmentStatus
                                                      .completed) ...[
                                                MySpacing.width(8),
                                                MyContainer(
                                                  onTap: () => controller
                                                      .billAppointment(data),
                                                  paddingAll: 8,
                                                  color: Colors.green
                                                      .withAlpha(30),
                                                  child: Icon(
                                                      LucideIcons.receipt,
                                                      size: 16,
                                                      color: Colors.green
                                                          .shade700),
                                                ),
                                              ],
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
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : TextButton(
                                      onPressed: controller.loadMore,
                                      child: MyText.bodyMedium("Load more",
                                          color: contentTheme.primary),
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
          TextButton(
              onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: Text('Delete',
                style: TextStyle(color: contentTheme.danger)),
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
        status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : '',
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
            Icon(LucideIcons.calendar_off,
                size: 48, color: contentTheme.secondary.withAlpha(100)),
            MySpacing.height(12),
            MyText.bodyMedium("No appointments match your search",
                muted: true),
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
            Icon(LucideIcons.circle_alert,
                size: 48, color: contentTheme.danger),
            MySpacing.height(12),
            MyText.bodyMedium(message,
                muted: true, textAlign: TextAlign.center),
            MySpacing.height(12),
            MyContainer(
              onTap: onRetry,
              borderRadiusAll: 8,
              color: contentTheme.primary.withAlpha(20),
              padding: MySpacing.xy(16, 10),
              child: MyText.bodyMedium("Retry",
                  color: contentTheme.primary, fontWeight: 600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date range row ─────────────────────────────────────────────────────────

class _DateRangeRow extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onClear;

  const _DateRangeRow({
    required this.fromDate,
    required this.toDate,
    required this.onFromTap,
    required this.onToTap,
    required this.onClear,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasRange = fromDate != null || toDate != null;
    final danger = Theme.of(context).colorScheme.error;
    return Row(
      children: [
        _dateField(context, 'From', fromDate, onFromTap),
        MySpacing.width(12),
        _dateField(context, 'To', toDate, onToTap),
        if (hasRange) ...[
          MySpacing.width(8),
          GestureDetector(
            onTap: onClear,
            child: Icon(LucideIcons.x, size: 16, color: danger),
          ),
        ],
      ],
    );
  }

  Widget _dateField(BuildContext context, String label, DateTime? date, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: cs.onSurface.withAlpha(60)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendar, size: 14, color: cs.onSurface.withAlpha(100)),
            MySpacing.width(6),
            Text(
              date != null ? _fmt(date) : label,
              style: TextStyle(
                fontSize: 12,
                color: date != null
                    ? cs.onSurface
                    : cs.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared search widgets ──────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
        prefixIcon:
            Icon(LucideIcons.search, size: 16, color: theme.hintColor),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: Icon(LucideIcons.x,
                      size: 15, color: theme.hintColor),
                  onPressed: onClear,
                ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: theme.colorScheme.onSurface.withAlpha(60)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: theme.colorScheme.onSurface.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primary : primary.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primary : primary.withAlpha(60),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : primary,
          ),
        ),
      ),
    );
  }
}
