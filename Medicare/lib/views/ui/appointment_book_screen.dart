import 'package:medicare/app_constant.dart';
import 'package:medicare/controller/ui/appointment_book_controller.dart';
import 'package:medicare/helpers/extention/date_time_extention.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

class AppointmentBookScreen extends StatefulWidget {
  const AppointmentBookScreen({super.key});

  @override
  State<AppointmentBookScreen> createState() => _AppointmentBookScreenState();
}

class _AppointmentBookScreenState extends State<AppointmentBookScreen> with UIMixin {
  late AppointmentBookController controller;

  @override
  void initState() {
    controller = Get.put(AppointmentBookController());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'admin_appointment_book_controller',
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
                      "Appointment Book",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Appointment'),
                        MyBreadcrumbItem(name: 'Book', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: MyContainer(
                  paddingAll: 24,
                  borderRadiusAll: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText.bodyMedium("Patient Details", fontWeight: 600),
                      MySpacing.height(20),
                      patientDetails(),
                      MySpacing.height(20),
                      MyText.bodyMedium("Appointment Details", fontWeight: 600),
                      MySpacing.height(20),
                      appointmentDetail(),
                      MySpacing.height(20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MyButton(
                              onPressed: controller.submit,
                              elevation: 0,
                              borderRadiusAll: 12,
                              backgroundColor: contentTheme.primary,
                              child: MyText.labelMedium("Submit", fontWeight: 600, color: contentTheme.onPrimary)),
                          MySpacing.width(20),
                          MyButton.outlined(
                              onPressed: () {},
                              borderRadiusAll: 12,
                              borderColor: theme.colorScheme.onSurface.withAlpha(80),
                              backgroundColor: contentTheme.secondary,
                              elevation: 0,
                              child: MyText.labelMedium("Cancel", fontWeight: 600))
                        ],
                      )
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

  Widget patientDetails() {
    return MyFlex(
      contentPadding: false,
      children: [
        MyFlexItem(
            sizes: 'lg-6 md-6',
            child: Column(
              children: [
                commonTextField(title: "First Name", hintText: "First Name", prefixIcon: Icon(LucideIcons.user_round, size: 16)),
                MySpacing.height(20),
                commonTextField(title: "Last Name", hintText: "Last Name", prefixIcon: Icon(LucideIcons.user_round, size: 16)),
                MySpacing.height(20),
                commonTextField(title: "Address", hintText: "Address", prefixIcon: Icon(LucideIcons.map_pin, size: 16)),
              ],
            )),
        MyFlexItem(
            sizes: 'lg-6 md-6',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                commonTextField(title: "Mobile Number", hintText: "Mobile Number", prefixIcon: Icon(LucideIcons.phone_call, size: 16)),
                MySpacing.height(20),
                commonTextField(title: "Email Address", hintText: "Email Address", prefixIcon: Icon(LucideIcons.mail, size: 16)),
                MySpacing.height(20),
                MyText.bodyMedium("Gender", fontWeight: 600),
                MySpacing.height(8),
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
                        .toList())
              ],
            )),
      ],
    );
  }

  Widget appointmentDetail() {
    return MyFlex(contentPadding: false, children: [
      MyFlexItem(
          sizes: 'lg-4 md-6',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.labelMedium("Date of appointment", fontWeight: 600, muted: true),
              MySpacing.height(8),
              TextFormField(
                onTap: () => controller.pickDate(),
                style: MyTextStyle.bodySmall(),
                controller: TextEditingController(text: controller.selectedDate != null ? dateFormatter.format(controller.selectedDate!) : ""),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: "Date of appointment",
                  hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
                  isCollapsed: true,
                  isDense: true,
                  prefixIcon: Icon(LucideIcons.calendar),
                  contentPadding: MySpacing.all(16),
                ),
              ),
            ],
          )),
      MyFlexItem(
          sizes: 'lg-4 md-6',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.labelMedium("From", fontWeight: 600, muted: true),
              MySpacing.height(8),
              TextFormField(
                onTap: () => controller.fromPickTime(),
                style: MyTextStyle.bodySmall(),
                controller: TextEditingController(
                    text: controller.fromSelectedTime != null ? timeFormatter.format(DateTime.now().applied(controller.fromSelectedTime!)) : ""),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: "From",
                  hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
                  isCollapsed: true,
                  isDense: true,
                  prefixIcon: Icon(LucideIcons.clock_3),
                  contentPadding: MySpacing.all(16),
                ),
              ),
            ],
          )),
      MyFlexItem(
          sizes: 'lg-4 md-6',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.labelMedium("To", fontWeight: 600, muted: true),
              MySpacing.height(8),
              TextFormField(
                onTap: () => controller.toPickTime(),
                style: MyTextStyle.bodySmall(),
                controller: TextEditingController(
                    text: controller.toSelectedTime != null ? timeFormatter.format(DateTime.now().applied(controller.toSelectedTime!)) : ""),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: "To",
                  hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
                  isCollapsed: true,
                  isDense: true,
                  prefixIcon: Icon(LucideIcons.calendar),
                  contentPadding: MySpacing.all(16),
                ),
              ),
            ],
          )),
      MyFlexItem(
        sizes: 'lg-6 md-6',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText.labelMedium("Consulting Doctor", fontWeight: 600, muted: true),
            MySpacing.height(8),
            DropdownButtonFormField<String>(
              value: controller.selectedConsultingDoctor,
              decoration: InputDecoration(
                  hintText: "Blood Group",
                  hintStyle: MyTextStyle.bodySmall(xMuted: true),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: MySpacing.all(12),
                  isCollapsed: true,
                  isDense: true,
                  prefixIcon: Icon(LucideIcons.user_plus, size: 16),
                  floatingLabelBehavior: FloatingLabelBehavior.never),
              dropdownColor: theme.cardTheme.color,
              onChanged: (value) => controller.onSelectedConsultingDoctor(value!),
              items: ["Bernardo james", "Andrea Lalema", "William Stephin"].map((doctor) {
                return DropdownMenuItem<String>(
                  value: doctor,
                  child: MyText.bodySmall(doctor, fontWeight: 600),
                );
              }).toList(),
            )
          ],
        ),
      ),
      MyFlexItem(
          sizes: 'lg-6 md-6',
          child: commonTextField(title: "Treatment", hintText: "Treatment detail", prefixIcon: Icon(LucideIcons.heart_pulse, size: 16))),
    ]);
  }

  Widget commonTextField({String? title, String? hintText, Widget? prefixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(title ?? "", fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextField(
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: hintText,
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
