import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/pharmacy_list_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_star_rating.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/views/layout/layout.dart';

class PharmacyListScreen extends StatefulWidget {
  const PharmacyListScreen({super.key});

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> with UIMixin {
  PharmacyListController controller = Get.put(PharmacyListController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'pharmacy_list_controller',
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
                      "Pharmacy List",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Pharmacy List', active: true),
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
                    MyFlexItem(
                        child: GridView.builder(
                      shrinkWrap: true,
                      primary: true,
                      itemCount: controller.products.length,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        mainAxisExtent: 500,
                      ),
                      itemBuilder: (context, index) {
                        dynamic product = controller.products[index];
                        return MyContainer(
                          onTap: () => controller.goToDetails(),
                          paddingAll: 20,
                          borderRadiusAll: 12,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyContainer(
                                height: 400,
                                width: double.infinity,
                                paddingAll: 0,
                                borderRadiusAll: 12,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                child: Image.asset(product['image'], fit: BoxFit.cover),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  MyText.bodyMedium(product['name']),
                                  MyStarRating(rating: product['rate'],activeColor: contentTheme.warning,)
                                ],
                              ),
                              MyText.bodyMedium('\$${product['price']}.00'),

                            ],
                          ),
                        );
                      },
                    )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
