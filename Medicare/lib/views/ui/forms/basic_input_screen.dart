import 'package:flutter/material.dart';
import 'package:medicare/app_constant.dart';
import 'package:medicare/controller/ui/forms/basic_input_controller.dart';
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
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class BasicInputScreen extends StatefulWidget {
  const BasicInputScreen({super.key});

  @override
  State<BasicInputScreen> createState() => _BasicInputScreenState();
}

class _BasicInputScreenState extends State<BasicInputScreen> with SingleTickerProviderStateMixin, UIMixin {
  late BasicInputController controller;

  @override
  void initState() {
    controller = BasicInputController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'basic_input_controller',
        builder: (controller) {
          return Column(
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium("Basic Input", fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [MyBreadcrumbItem(name: 'Form'), MyBreadcrumbItem(name: 'Basic Input', active: true)],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing / 2),
                child: MyFlex(
                  children: [
                    MyFlexItem(sizes: 'lg-2.4', child: radioButton()),
                    MyFlexItem(sizes: 'lg-2.4', child: selectDate()),
                    MyFlexItem(sizes: 'lg-2.4', child: selectTime()),
                    MyFlexItem(sizes: 'lg-2.4', child: selectRange()),
                    MyFlexItem(sizes: 'lg-2.4', child: selectDateTime()),
                    MyFlexItem(sizes: 'lg-9', child: buildBuilder()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildBuilder() {
    return MyContainer(
      borderRadiusAll: 12,
      paddingAll: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.settings,
                color: colorScheme.primary,
                size: 16
              ),
              MySpacing.width(12),
              MyText.titleMedium(
                "builder",
                fontWeight: 600,
                color: colorScheme.primary
              ),
            ],
          ),
          Padding(
            padding: MySpacing.all(flexSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyFlex(
                  contentPadding: false,
                  children: [
                    MyFlexItem(
                        sizes: 'lg-6',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 180, child: MyText.labelLarge("Floating Label Type")),
                                PopupMenuButton(
                                    onSelected: controller.onChangeLabelType,
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    shape: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
                                    itemBuilder: (BuildContext context) {
                                      return FloatingLabelBehavior.values.map((behavior) {
                                        return PopupMenuItem(
                                          value: behavior,
                                          height: 32,
                                          child: MyText.bodySmall(
                                            behavior.name.capitalize!,
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: 600,
                                          ),
                                        );
                                      }).toList();
                                    },
                                    color: theme.cardTheme.color,
                                    child: MyContainer.bordered(
                                      padding: MySpacing.xy(12, 8),
                                      borderRadiusAll: 8,
                                      child: Row(
                                        children: <Widget>[
                                          MyText.labelMedium(
                                            controller.floatingLabelBehavior.name.capitalize!,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(left: 4),
                                            child: Icon(
                                              LucideIcons.chevron_down,
                                              size: 22,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          )
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                            MySpacing.height(12),
                            Row(
                              children: [
                                SizedBox(width: 180, child: MyText.labelLarge("Border Type")),
                                PopupMenuButton(
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    shape: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
                                    onSelected: controller.onChangeBorderType,
                                    itemBuilder: (BuildContext context) {
                                      return TextFieldBorderType.values.map((borderType) {
                                        return PopupMenuItem(
                                          value: borderType,
                                          height: 32,
                                          child: MyText.bodySmall(
                                            borderType.name.capitalize!,
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: 600,
                                          ),
                                        );
                                      }).toList();
                                    },
                                    color: theme.cardTheme.color,
                                    child: MyContainer.bordered(
                                      borderRadiusAll: 8,
                                      padding: MySpacing.xy(12, 8),
                                      child: Row(
                                        children: <Widget>[
                                          MyText.labelMedium(
                                            controller.borderType.name.capitalize!,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(left: 4),
                                            child: Icon(
                                              LucideIcons.chevron_down,
                                              size: 22,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          )
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ],
                        )),
                    MyFlexItem(
                        sizes: 'lg-6',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(width: 100, child: MyText.labelLarge("Filled")),
                                        Switch(
                                          onChanged: controller.onChangedFilledChecked,
                                          value: controller.filled,
                                          activeColor: theme.colorScheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          // visualDensity: getCompactDensity,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 100, child: MyText.labelLarge("Disabled")),
                                        Switch(
                                          onChanged: controller.onChangedDisabledChecked,
                                          value: controller.disabled,
                                          activeColor: theme.colorScheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 100, child: MyText.labelLarge("Read Only")),
                                        Switch(
                                          onChanged: controller.onChangedReadOnlyChecked,
                                          value: controller.readOnly,
                                          activeColor: theme.colorScheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 100, child: MyText.labelLarge("Helper Text")),
                                        Switch(
                                          onChanged: controller.onChangedHelperTextChecked,
                                          value: controller.helperText,
                                          activeColor: theme.colorScheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                MySpacing.width(12),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(width: 100, child: MyText.labelLarge("Inline Text")),
                                        Switch(
                                          onChanged: controller.onChangedInlineTextChecked,
                                          value: controller.inlineText,
                                          activeColor: theme.colorScheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 100, child: MyText.labelLarge("Pilled")),
                                        Switch(
                                          onChanged: controller.onChangedPilledChecked,
                                          value: controller.pilled,
                                          activeColor: theme.colorScheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 100, child: MyText.labelLarge("Prefix Icon")),
                                        Switch(
                                          onChanged: controller.onChangedPrefixIconChecked,
                                          value: controller.prefixIcon,
                                          activeColor: theme.colorScheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 100, child: MyText.labelLarge("Suffix Icon")),
                                        Switch(
                                          onChanged: controller.onChangedSuffixIconChecked,
                                          value: controller.suffixIcon,
                                          activeColor: theme.colorScheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ))
                  ],
                ),
                MySpacing.height(20),
                TextField(
                  controller: TextEditingController(text: "Hello,"),
                  enabled: controller.disabled,
                  readOnly: controller.readOnly,
                  style: MyTextStyle.bodySmall(fontWeight: 600),
                  decoration: InputDecoration(
                    suffixIcon: controller.suffixIcon ? Icon(LucideIcons.nfc) : null,
                    prefixIcon: controller.prefixIcon ? Icon(LucideIcons.smartphone_nfc) : null,
                    labelText: "Inputs Label",
                    suffixText: controller.inlineText ? "Inline Text" : "",
                    helperText: controller.helperText ? "Demo Helper Text" : "",
                    border: controller.inputBorder,
                    focusedBorder: controller.inputBorder,
                    filled: controller.filled,
                    enabledBorder: controller.inputBorder,
                    floatingLabelBehavior: controller.floatingLabelBehavior,
                    contentPadding: MySpacing.all(12),
                    hintStyle: MyTextStyle.bodySmall(),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget radioButton() {
    return MyContainer(
      height: 130,
      borderRadiusAll: 12,
      paddingAll: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Radio Button", fontWeight: 600),
          MySpacing.height(20),
          Row(
            children: [
              MyText.labelLarge("Gender"),
              MySpacing.width(16),
              Expanded(
                child: Wrap(
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
                                  groupValue: controller.selectedGender,
                                  onChanged: controller.onChangeGender,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                MySpacing.width(8),
                                MyText.bodySmall(gender.name.capitalize!)
                              ],
                            ),
                          ),
                        )
                        .toList()),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget selectDate() {
    return MyContainer(
      height: 130,
      borderRadiusAll: 12,
      paddingAll: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Date", fontWeight: 600),
          MySpacing.height(20),
          MyButton.outlined(
            onPressed: () {
              controller.pickDate();
            },
            borderColor: colorScheme.primary,
            padding: MySpacing.xy(16, 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  LucideIcons.calendar,
                  color: colorScheme.primary,
                  size: 16,
                ),
                MySpacing.width(10),
                MyText.labelMedium(controller.selectedDate != null ? dateFormatter.format(controller.selectedDate!) : "Select Date",
                    fontWeight: 600, color: colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget selectTime() {
    return MyContainer(
      height: 130,
      borderRadiusAll: 12,
      paddingAll: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Time", fontWeight: 600),
          MySpacing.height(20),
          MyButton.outlined(
            onPressed: () {
              controller.pickTime();
            },
            borderColor: colorScheme.primary,
            padding: MySpacing.xy(16, 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  LucideIcons.clock_3,
                  color: colorScheme.primary,
                  size: 16,
                ),
                MySpacing.width(10),
                MyText.labelMedium(
                    controller.selectedTime != null ? timeFormatter.format(DateTime.now().applied(controller.selectedTime!)) : "Select Time",
                    fontWeight: 600,
                    color: colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget selectRange() {
    return MyContainer(
      height: 130,
      borderRadiusAll: 12,
      paddingAll: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Range", fontWeight: 600),
          MySpacing.height(20),
          MyButton.outlined(
            onPressed: () {
              controller.pickDateRange();
            },
            borderColor: colorScheme.primary,
            padding: MySpacing.xy(16, 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  LucideIcons.calendar,
                  color: colorScheme.primary,
                  size: 16,
                ),
                MySpacing.width(10),
                MyText.labelMedium(
                    controller.selectedDateTimeRange != null
                        ? "${dateFormatter.format(controller.selectedDateTimeRange!.start)} - ${dateFormatter.format(controller.selectedDateTimeRange!.end)}"
                        : "Select Range",
                    fontWeight: 600,
                    color: colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget selectDateTime() {
    return MyContainer(
      height: 130,
      borderRadiusAll: 12,
      paddingAll: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Range", fontWeight: 600),
          MySpacing.height(20),
          MyButton.outlined(
            onPressed: () {
              controller.pickDateTime();
            },
            borderColor: colorScheme.primary,
            padding: MySpacing.xy(16, 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  LucideIcons.calendar_check,
                  color: colorScheme.primary,
                  size: 16,
                ),
                MySpacing.width(10),
                MyText.labelMedium(
                    controller.selectedDateTime != null
                        ? "${dateFormatter.format(controller.selectedDateTime!)} ${timeFormatter.format(controller.selectedDateTime!)}"
                        : "Select Date & Time",
                    fontWeight: 600,
                    color: colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
