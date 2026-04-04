import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/app_constant.dart';
import 'package:medicare/controller/ui/patient_add_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/views/layout/layout.dart';

class PatientAddScreen extends StatefulWidget {
  const PatientAddScreen({super.key});

  @override
  State<PatientAddScreen> createState() => _PatientAddScreenState();
}

class _PatientAddScreenState extends State<PatientAddScreen> with UIMixin {
  PatientAddController controller = Get.put(PatientAddController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'admin_patient_add_controller',
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('Patient Add',
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'People'),
                        MyBreadcrumbItem(name: 'Patient Add', active: true),
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
                      MyText.titleMedium('Basic Information', fontWeight: 600),
                      MySpacing.height(20),
                      if (controller.errorMessage != null) ...[
                        Container(
                          padding: MySpacing.all(12),
                          decoration: BoxDecoration(
                            color: contentTheme.danger.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: MyText.bodySmall(controller.errorMessage!,
                              color: contentTheme.danger),
                        ),
                        MySpacing.height(16),
                      ],
                      MyFlex(
                        contentPadding: false,
                        children: [
                          MyFlexItem(
                            sizes: 'lg-6 md-6',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _field('First Name', 'First Name',
                                    LucideIcons.user_round,
                                    controller.firstNameTE),
                                MySpacing.height(20),
                                _field('Last Name', 'Last Name',
                                    LucideIcons.user_round,
                                    controller.lastNameTE),
                                MySpacing.height(20),
                                _field('Email Address', 'Email Address',
                                    LucideIcons.mail, controller.emailTE),
                                MySpacing.height(20),
                                _field('Address', 'Address',
                                    LucideIcons.map_pin, controller.addressTE),
                                MySpacing.height(20),
                                MyText.labelMedium('Blood Group',
                                    fontWeight: 600, muted: true),
                                MySpacing.height(8),
                                DropdownButtonFormField<BloodType>(
                                  dropdownColor: contentTheme.background,
                                  isDense: true,
                                  value: controller.bloodType,
                                  style: MyTextStyle.bodySmall(),
                                  items: BloodType.values
                                      .map((bt) => DropdownMenuItem<BloodType>(
                                            value: bt,
                                            child: MyText.labelMedium(bt.name),
                                          ))
                                      .toList(),
                                  icon:
                                      const Icon(LucideIcons.chevron_down, size: 20),
                                  decoration: InputDecoration(
                                    hintText: 'Blood Group',
                                    hintStyle:
                                        MyTextStyle.bodySmall(xMuted: true),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    contentPadding: MySpacing.all(12),
                                    isCollapsed: true,
                                    isDense: true,
                                    prefixIcon: const Icon(
                                        LucideIcons.heart_pulse,
                                        size: 16),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                  ),
                                  onChanged: controller.onChangeBloodType,
                                ),
                              ],
                            ),
                          ),
                          MyFlexItem(
                            sizes: 'lg-6 md-6',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _numericField('Mobile Number', 'Mobile Number',
                                    LucideIcons.phone_call,
                                    controller.phoneTE,
                                    length: 15),
                                MySpacing.height(20),
                                MyText.bodyMedium('Gender', fontWeight: 600),
                                MySpacing.height(12),
                                Wrap(
                                  spacing: 16,
                                  children: Gender.values
                                      .map((g) => InkWell(
                                            onTap: () =>
                                                controller.onChangeGender(g),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Radio<Gender>(
                                                  value: g,
                                                  activeColor:
                                                      contentTheme.primary,
                                                  groupValue: controller.gender,
                                                  onChanged: controller
                                                      .onChangeGender,
                                                  visualDensity:
                                                      getCompactDensity,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                MySpacing.width(8),
                                                MyText.labelMedium(
                                                    g.name.capitalize!),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                                MySpacing.height(20),
                                _datePicker('Date of Birth', controller),
                                MySpacing.height(20),
                                _field('Medical History / Injury',
                                    'e.g. Hypertension, Asthma',
                                    LucideIcons.shield_x,
                                    controller.medicalHistoryTE),
                              ],
                            ),
                          ),
                        ],
                      ),
                      MySpacing.height(24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MyContainer(
                            onTap: controller.saving
                                ? null
                                : controller.savePatient,
                            padding: MySpacing.xy(12, 8),
                            color: contentTheme.primary,
                            borderRadiusAll: 8,
                            child: controller.saving
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: contentTheme.onPrimary),
                                  )
                                : MyText.labelMedium('Save Patient',
                                    color: contentTheme.onPrimary,
                                    fontWeight: 600),
                          ),
                          MySpacing.width(12),
                          MyContainer(
                            onTap: () => Get.back(),
                            padding: MySpacing.xy(12, 8),
                            borderRadiusAll: 8,
                            color: contentTheme.secondary.withAlpha(32),
                            child: MyText.labelMedium('Cancel',
                                color: contentTheme.secondary, fontWeight: 600),
                          ),
                        ],
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

  Widget _field(String title, String hint, IconData icon,
      TextEditingController te) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(title, fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextFormField(
          controller: te,
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: hint,
            counterText: '',
            hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
            isCollapsed: true,
            isDense: true,
            prefixIcon: Icon(icon, size: 16),
            contentPadding: MySpacing.all(16),
          ),
        ),
      ],
    );
  }

  Widget _numericField(String title, String hint, IconData icon,
      TextEditingController te,
      {int? length}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(title, fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextFormField(
          controller: te,
          keyboardType: TextInputType.phone,
          maxLength: length,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
          ],
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: hint,
            counterText: '',
            hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
            isCollapsed: true,
            isDense: true,
            prefixIcon: Icon(icon, size: 16),
            contentPadding: MySpacing.all(16),
          ),
        ),
      ],
    );
  }

  Widget _datePicker(String title, PatientAddController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(title, fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextFormField(
          onTap: ctrl.pickDate,
          readOnly: true,
          controller: TextEditingController(
              text: ctrl.selectedDate != null
                  ? dateFormatter.format(ctrl.selectedDate!)
                  : ''),
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Select date',
            hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
            isCollapsed: true,
            isDense: true,
            prefixIcon: const Icon(LucideIcons.cake, size: 16),
            contentPadding: MySpacing.all(16),
          ),
        ),
      ],
    );
  }
}
