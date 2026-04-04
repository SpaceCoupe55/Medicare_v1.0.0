import 'package:animate_gradient/animate_gradient.dart';
import 'package:medicare/controller/layout/auth_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_responsiv.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';

class AuthLayout extends StatelessWidget {
  final Widget? child;

  final AuthLayoutController controller = AuthLayoutController();

  AuthLayout({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return MyResponsive(builder: (BuildContext context, _, screenMT) {
      return GetBuilder(
          init: controller,
          builder: (controller) {
            return screenMT.isMobile
                ? mobileScreen(context)
                : largeScreen(context);
          });
    });
  }

  Widget mobileScreen(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      body: Container(
        padding: MySpacing.top(MySpacing.safeAreaTop(context) + 20),
        height: MediaQuery.of(context).size.height,
        color: theme.cardTheme.color,
        child: SingleChildScrollView(
          key: controller.scrollKey,
          child: child,
        ),
      ),
    );
  }

  Widget largeScreen(BuildContext context) {
    return Scaffold(
        key: controller.scaffoldKey,
        backgroundColor: Colors.blue,
        body: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            AnimateGradient(
              primaryColors: [Colors.brown, Colors.grey],
              secondaryColors: [Colors.grey, Colors.brown],
            ),
            MyFlex(
              wrapAlignment: WrapAlignment.center,
              wrapCrossAlignment: WrapCrossAlignment.start,
              runAlignment: WrapAlignment.center,
              spacing: 0,
              runSpacing: 0,
              children: [
                MyFlexItem(
                  sizes: "xxl-3 lg-4 md-6 sm-10",
                  child: MyContainer(
                    paddingAll: 0,
                    borderRadiusAll: 12,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: child ?? Container(),
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}
