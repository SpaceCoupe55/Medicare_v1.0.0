import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/patient_list_controller.dart';
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
import 'package:medicare/views/layout/layout.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> with UIMixin {
  PatientListController controller = Get.put(PatientListController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<PatientListController>(
        init: controller,
        tag: 'admin_patient_list_controller',
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium("Patients",
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'People'),
                        MyBreadcrumbItem(name: 'Patients', active: true),
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
                          MyText.bodyMedium("Patient List",
                              fontWeight: 600, muted: true),
                          MyContainer(
                            onTap: controller.addPatient,
                            padding: MySpacing.xy(12, 8),
                            borderRadiusAll: 8,
                            color: contentTheme.primary,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.user_plus,
                                    size: 14,
                                    color: contentTheme.onPrimary),
                                MySpacing.width(6),
                                MyText.labelSmall("Add Patient",
                                    fontWeight: 600,
                                    color: contentTheme.onPrimary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      MySpacing.height(16),

                      // ── Search bar ───────────────────────────────────────
                      _SearchBar(
                        controller: controller.searchTE,
                        hint: 'Search by name, phone, email, blood type…',
                        onChanged: controller.onSearchChanged,
                        onClear: controller.clearSearch,
                      ),
                      MySpacing.height(12),

                      // ── Filter chips ─────────────────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: controller.genderFilter == null &&
                                controller.bloodTypeFilter == null,
                            onTap: () {
                              controller.setGenderFilter(null);
                              controller.setBloodTypeFilter(null);
                            },
                          ),
                          _FilterChip(
                            label: 'Male',
                            selected: controller.genderFilter == 'Male',
                            onTap: () => controller.setGenderFilter('Male'),
                          ),
                          _FilterChip(
                            label: 'Female',
                            selected: controller.genderFilter == 'Female',
                            onTap: () => controller.setGenderFilter('Female'),
                          ),
                          for (final bt in kBloodTypes)
                            _FilterChip(
                              label: bt,
                              selected: controller.bloodTypeFilter == bt,
                              onTap: () =>
                                  controller.setBloodTypeFilter(bt),
                            ),
                        ],
                      ),
                      MySpacing.height(10),

                      // ── Result count ─────────────────────────────────────
                      if (!controller.loading)
                        MyText.bodySmall(
                          'Showing ${controller.patients.length} of '
                          '${controller.totalCount} patients',
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
                      else if (controller.patients.isEmpty)
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
                              DataColumn(label: MyText.labelMedium('Name', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelMedium('Sex', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelMedium('Address', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelMedium('Mobile Number', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelMedium('Birth Date', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelMedium('Age', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelMedium('Blood Group', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelMedium('Status', color: contentTheme.primary)),
                              DataColumn(label: MyText.labelMedium('Action', color: contentTheme.primary)),
                            ],
                            rows: controller.patients
                                .mapIndexed((index, data) => DataRow(cells: [
                                      DataCell(SizedBox(
                                        width: 200,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            MyContainer.rounded(
                                              paddingAll: 0,
                                              height: 32,
                                              width: 32,
                                              child: Image.asset(
                                                  Images.avatars[index %
                                                      Images.avatars.length],
                                                  fit: BoxFit.cover),
                                            ),
                                            MySpacing.width(16),
                                            Flexible(
                                                child: MyText.bodySmall(
                                                    data.name,
                                                    overflow: TextOverflow
                                                        .ellipsis)),
                                          ],
                                        ),
                                      )),
                                      DataCell(MyText.bodySmall(data.gender)),
                                      DataCell(SizedBox(
                                          width: 200,
                                          child: MyText.bodySmall(data.address,
                                              overflow: TextOverflow.ellipsis))),
                                      DataCell(SizedBox(
                                          width: 120,
                                          child: MyText.bodySmall(
                                              data.mobileNumber))),
                                      DataCell(SizedBox(
                                          width: 100,
                                          child: MyText.bodySmall(
                                              Utils.getDateStringFromDateTime(
                                                  data.birthDate)))),
                                      DataCell(
                                          MyText.bodySmall('${data.age}')),
                                      DataCell(
                                          MyText.bodySmall(data.bloodGroup)),
                                      DataCell(SizedBox(
                                          width: 80,
                                          child:
                                              MyText.bodySmall(data.status))),
                                      DataCell(Row(
                                        children: [
                                          MyContainer(
                                            onTap: () =>
                                                controller.goDetailScreen(data),
                                            paddingAll: 8,
                                            color: contentTheme.secondary
                                                .withAlpha(32),
                                            child: Icon(LucideIcons.eye,
                                                size: 16),
                                          ),
                                          MySpacing.width(8),
                                          MyContainer(
                                            onTap: () =>
                                                controller.goEditScreen(data),
                                            paddingAll: 8,
                                            color: contentTheme.secondary
                                                .withAlpha(32),
                                            child: Icon(LucideIcons.pencil,
                                                size: 16),
                                          ),
                                          MySpacing.width(8),
                                          MyContainer(
                                            onTap: () => _confirmDelete(
                                              context,
                                              'Delete patient "${data.name}"?',
                                              () => controller
                                                  .deletePatient(data.id),
                                            ),
                                            paddingAll: 8,
                                            color: contentTheme.danger
                                                .withAlpha(30),
                                            child: Icon(LucideIcons.trash_2,
                                                size: 16,
                                                color: contentTheme.danger),
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
            child:
                Text('Delete', style: TextStyle(color: contentTheme.danger)),
          ),
        ],
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
            Icon(LucideIcons.inbox,
                size: 48, color: contentTheme.secondary.withAlpha(100)),
            MySpacing.height(12),
            MyText.bodyMedium("No patients match your search", muted: true),
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
          borderSide:
              BorderSide(color: theme.colorScheme.onSurface.withAlpha(60)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: theme.colorScheme.onSurface.withAlpha(60)),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
