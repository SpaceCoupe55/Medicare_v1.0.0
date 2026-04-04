import 'package:medicare/app_constant.dart';
import 'package:medicare/controller/ui/patient_edit_controller.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

class PatientEditScreen extends StatefulWidget {
  const PatientEditScreen({super.key});

  @override
  State<PatientEditScreen> createState() => _PatientEditScreenState();
}

class _PatientEditScreenState extends State<PatientEditScreen> with UIMixin {
  PatientEditController controller = Get.put(PatientEditController());
  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'admin_patient_edit_controller',
        builder: (controller) {
          return Column(
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium(
                      "Patient Edit",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Admin'),
                        MyBreadcrumbItem(name: 'Patient Edit', active: true),
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
                      MyText.titleMedium("Basic Information", fontWeight: 600),
                      MySpacing.height(20),
                      MyFlex(
                        contentPadding: false,
                        children: [
                          MyFlexItem(
                            sizes: 'lg-6 md-6',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                commonTextField(title: "First Name", hintText: "First Name", prefixIcon: Icon(LucideIcons.user_round, size: 16), teController: controller.firstNameTE),
                                MySpacing.height(20),
                                commonTextField(title: "Last Name", hintText: "Last Name", prefixIcon: Icon(LucideIcons.user_round, size: 16), teController: controller.lastNameTE),
                                MySpacing.height(20),
                                commonTextField(title: "User Name", hintText: "User Name", prefixIcon: Icon(LucideIcons.user_round, size: 16), teController: controller.userNameTE),
                                MySpacing.height(20),
                                commonTextField(title: "Address", hintText: "Address", prefixIcon: Icon(LucideIcons.map_pin, size: 16), teController: controller.addressTE),
                                MySpacing.height(20),
                                MyText.labelMedium("Blood Group", fontWeight: 600, muted: true),
                                MySpacing.height(8),
                                DropdownButtonFormField<BloodType>(
                                    dropdownColor: contentTheme.background,
                                    isDense: true,
                                    style: MyTextStyle.bodySmall(),
                                    items: BloodType.values
                                        .map((category) => DropdownMenuItem<BloodType>(
                                              value: category,
                                              child: MyText.labelMedium(category.name.capitalize!),
                                            ))
                                        .toList(),
                                    icon: Icon(LucideIcons.chevron_down, size: 20),
                                    decoration: InputDecoration(
                                        hintText: "Blood Group",
                                        hintStyle: MyTextStyle.bodySmall(xMuted: true),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: MySpacing.all(12),
                                        isCollapsed: true,
                                        isDense: true,
                                        prefixIcon: Icon(LucideIcons.heart_pulse, size: 16),
                                        floatingLabelBehavior: FloatingLabelBehavior.never),
                                    onChanged: controller.basicValidator.onChanged<Object?>('blood_group')),
                                MySpacing.height(20),
                                commonTextField(title: "Sugger", hintText: "Sugger", prefixIcon: Icon(LucideIcons.torus, size: 16), numbered: true, length: 3, teController: controller.suggerTE),
                              ],
                            ),
                          ),
                          MyFlexItem(
                            sizes: 'lg-6 md-6',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                commonTextField(
                                    title: "Mobile Number",
                                    hintText: "Mobile Number",
                                    prefixIcon: Icon(LucideIcons.phone_call, size: 16),
                                    numbered: true,
                                    length: 10,
                                    teController: controller.mobileNumberTE),
                                MySpacing.height(20),
                                commonTextField(title: "Age", hintText: "Age", prefixIcon: Icon(LucideIcons.person_standing, size: 16), numbered: true, length: 2, teController: controller.ageTE),
                                MySpacing.height(20),
                                MyText.bodyMedium("Gender", fontWeight: 600),
                                MySpacing.height(20),
                                Wrap(
                                    spacing: 16,
                                    children: Gender.values
                                        .map(
                                          (gender) => InkWell(
                                            onTap: () => controller.onChangeGender(gender),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Radio<Gender>(
                                                  value: gender,
                                                  activeColor: theme.colorScheme.primary,
                                                  groupValue: controller.gender,
                                                  onChanged: (value) => controller.onChangeGender(value),
                                                  visualDensity: getCompactDensity,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                MySpacing.width(8),
                                                MyText.labelMedium(
                                                  gender.name.capitalize!,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList()),
                                MySpacing.height(20),
                                commonTextField(
                                    title: "Date Of Birth",
                                    hintText: "Select Date",
                                    prefixIcon: Icon(LucideIcons.cake, size: 16),
                                    onTap: controller.pickDate,
                                    teController: TextEditingController(text: controller.selectedDate != null ? dateFormatter.format(controller.selectedDate!) : "")),
                                MySpacing.height(20),
                                commonTextField(
                                    title: "Blood Pressure",
                                    hintText: "Blood Pressure",
                                    prefixIcon: Icon(LucideIcons.heart_pulse, size: 16),
                                    numbered: true,
                                    length: 3,
                                    teController: controller.bloodPressureTE),
                                MySpacing.height(20),
                                commonTextField(title: "Injury/Condition", hintText: "Injury/Condition", prefixIcon: Icon(LucideIcons.shield_x, size: 16), teController: controller.injuryTE),
                              ],
                            ),
                          ),
                        ],
                      ),
                      MySpacing.height(20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MyContainer(
                            onTap: () {},
                            padding: MySpacing.xy(12, 8),
                            color: contentTheme.primary,
                            borderRadiusAll: 8,
                            child: MyText.labelMedium("Submit", color: contentTheme.onPrimary, fontWeight: 600),
                          ),
                          MySpacing.width(20),
                          MyContainer(
                            onTap: () {},
                            padding: MySpacing.xy(12, 8),
                            borderRadiusAll: 8,
                            color: contentTheme.secondary.withAlpha(32),
                            child: MyText.labelMedium("Cancel", color: contentTheme.secondary, fontWeight: 600),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget commonTextField({String? title, String? hintText, Widget? prefixIcon, void Function()? onTap, TextEditingController? teController, bool numbered = false, int? length}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(title ?? "", fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextFormField(
          onTap: onTap ?? () {},
          controller: teController,
          keyboardType: numbered ? TextInputType.phone : null,
          maxLength: length,
          inputFormatters: numbered ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))] : null,
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: hintText,
            counterText: "",
            hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
            isCollapsed: true,
            isDense: true,
            prefixIcon: prefixIcon,
            contentPadding: MySpacing.all(16),
          ),
        ),
      ],
    );
  }
}
