import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/pharmacy_checkout_controller.dart';
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

class PharmacyCheckoutScreen extends StatefulWidget {
  const PharmacyCheckoutScreen({super.key});

  @override
  State<PharmacyCheckoutScreen> createState() => _PharmacyCheckoutScreenState();
}

class _PharmacyCheckoutScreenState extends State<PharmacyCheckoutScreen> with UIMixin {
  PharmacyCheckoutController controller = Get.put(PharmacyCheckoutController());
  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'pharmacy_checkout_controller',
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
                      "Checkout",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Checkout', active: true),
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
                    MyFlexItem(sizes: 'lg-8 md-6', child: billingAddress()),
                    MyFlexItem(sizes: 'lg-4 md-6', child: yourOrder()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget billingAddress() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyMedium("Billing Address", fontWeight: 600),
          MySpacing.height(20),
          MyFlex(contentPadding: false, children: [
            MyFlexItem(sizes: 'lg-6', child: commonTextField("First Name", "First Name")),
            MyFlexItem(sizes: 'lg-6', child: commonTextField("Last Name", "Last Name")),
            MyFlexItem(sizes: 'lg-6', child: commonTextField("Username", "Username")),
            MyFlexItem(sizes: 'lg-6', child: commonTextField("Email", "Email")),
            MyFlexItem(sizes: 'lg-6', child: commonTextField("Address", "Address")),
            MyFlexItem(sizes: 'lg-6', child: commonTextField("Country", "Country")),
            MyFlexItem(sizes: 'lg-6', child: commonTextField("State", "State")),
            MyFlexItem(sizes: 'lg-6', child: commonTextField("Zip", "Zip")),
          ]),
          MySpacing.height(20),
          Theme(
            data: ThemeData(colorScheme: theme.colorScheme),
            child: CheckboxListTile(
              value: controller.isBillingAddress,
              onChanged: (value) => controller.onBillingAddress(),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: MySpacing.x(0),
              visualDensity: VisualDensity.compact,
              title: MyText.bodySmall("Shipping address is the same as my billing address", fontWeight: 600),
            ),
          ),
          Theme(
            data: ThemeData(colorScheme: theme.colorScheme),
            child: CheckboxListTile(
              value: controller.isSaveInformation,
              onChanged: (value) => controller.onSaveInformation(),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: MySpacing.x(0),
              visualDensity: VisualDensity.compact,
              title: MyText.bodySmall("Save this information for next time", fontWeight: 600),
            ),
          ),
          MySpacing.height(20),
          MyContainer(
            onTap: (){},
            padding: MySpacing.xy(12, 8),
            color: contentTheme.primary,
            child: MyText.bodySmall("Continue to checkout", fontWeight: 600, color: contentTheme.onPrimary),
          )
        ],
      ),
    );
  }

  Widget commonTextField(String title, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(title, fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextField(
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              hintText: hintText,
              hintStyle: MyTextStyle.bodySmall(),
              isDense: true,
              isCollapsed: true,
              contentPadding: MySpacing.all(16)),
        ),
      ],
    );
  }

  Widget yourOrder() {
    return MyContainer(
      paddingAll: 0,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: MySpacing.all(20),
            child: MyText.titleMedium("Your Order", fontWeight: 600),
          ),
          Divider(height: 0),
          Padding(
            padding: MySpacing.xy(24,20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.bodyMedium("Product", fontWeight: 600),
                    MyText.bodyMedium("Total", fontWeight: 600),
                  ],
                ),
                MySpacing.height(20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: MyText.bodySmall("Safi Natural Blood Purifier Syrup 200 ml Manufactured By Hamdard (Wakf) Laboratories",
                            fontWeight: 600,xMuted: true)),
                    MySpacing.width(20),
                    MyText.bodySmall("\$120", fontWeight: 600,xMuted: true),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 0),
          Padding(
            padding: MySpacing.nBottom(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText.bodyMedium("Subtotal",fontWeight: 600),
                MyText.bodyMedium("\$120.00",fontWeight: 600),
              ],
            ),
          ),
          Padding(
            padding: MySpacing.nBottom(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText.bodyMedium("Shipping",fontWeight: 600),
                MyText.bodyMedium("\$20.00",fontWeight: 600),
              ],
            ),
          ),
          Padding(
            padding: MySpacing.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText.bodyMedium("Tax",fontWeight: 600),
                MyText.bodyMedium("\$0.00",fontWeight: 600),
              ],
            ),
          ),
          Divider(height: 0),
          Padding(
            padding: MySpacing.xy(24,20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText.titleMedium("Total",fontWeight: 700),
                MyText.bodyMedium("\$140.00",fontWeight: 700),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
