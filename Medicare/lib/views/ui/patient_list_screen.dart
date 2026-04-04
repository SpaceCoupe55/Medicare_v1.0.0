import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/patient_list_controller.dart';
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
      child: GetBuilder(
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
                    MyText.titleMedium("Patients", fontSize: 18, fontWeight: 600),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyText.bodyMedium("Patient List", fontWeight: 600, muted: true),
                          MyContainer(
                            onTap: controller.addPatient,
                            padding: MySpacing.xy(12, 8),
                            borderRadiusAll: 8,
                            color: contentTheme.primary,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.user_plus, size: 14, color: contentTheme.onPrimary),
                                MySpacing.width(6),
                                MyText.labelSmall("Add Patient", fontWeight: 600, color: contentTheme.onPrimary),
                              ],
                            ),
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
                      else if (controller.patients.isEmpty)
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
                                              child: Image.asset(Images.avatars[index % Images.avatars.length], fit: BoxFit.cover),
                                            ),
                                            MySpacing.width(16),
                                            Flexible(child: MyText.bodySmall(data.name, overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      )),
                                      DataCell(MyText.bodySmall(data.gender)),
                                      DataCell(SizedBox(width: 200, child: MyText.bodySmall(data.address, overflow: TextOverflow.ellipsis))),
                                      DataCell(SizedBox(width: 120, child: MyText.bodySmall(data.mobileNumber))),
                                      DataCell(SizedBox(width: 100, child: MyText.bodySmall(Utils.getDateStringFromDateTime(data.birthDate)))),
                                      DataCell(MyText.bodySmall('${data.age}')),
                                      DataCell(MyText.bodySmall(data.bloodGroup)),
                                      DataCell(SizedBox(width: 80, child: MyText.bodySmall(data.status))),
                                      DataCell(Row(
                                        children: [
                                          MyContainer(
                                            onTap: () => controller.goDetailScreen(data),
                                            paddingAll: 8,
                                            color: contentTheme.secondary.withAlpha(32),
                                            child: Icon(LucideIcons.eye, size: 16),
                                          ),
                                          MySpacing.width(12),
                                          MyContainer(
                                            onTap: () => controller.goEditScreen(data),
                                            paddingAll: 8,
                                            color: contentTheme.secondary.withAlpha(32),
                                            child: Icon(LucideIcons.pencil, size: 16),
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: MySpacing.y(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox, size: 48, color: contentTheme.secondary.withAlpha(100)),
            MySpacing.height(12),
            MyText.bodyMedium("No patients yet", muted: true),
            MySpacing.height(12),
            MyContainer(
              onTap: controller.addPatient,
              borderRadiusAll: 8,
              color: contentTheme.primary.withAlpha(20),
              padding: MySpacing.xy(16, 10),
              child: MyText.bodyMedium("Add First Patient", color: contentTheme.primary, fontWeight: 600),
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
