import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:medicare/controller/ui/home_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_card.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_star_rating.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/images.dart';
import 'package:medicare/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with UIMixin {
  HomeController controller = Get.put(HomeController());
  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'home_controller',
        builder: (controller) {
          return Column(
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium(
                      "Home",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Home', active: true),
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
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyFlex(
                          children: [
                            MyFlexItem(
                                sizes: 'lg-8',
                                child: Column(
                                  children: [poster(), MySpacing.height(20), features()],
                                )),
                            MyFlexItem(sizes: 'lg-4', child: categories()),
                          ],
                        ),
                        MySpacing.height(20),
                        MyText.titleLarge("Book an appointment for ab in-clinic consultation", fontWeight: 600),
                        MySpacing.height(20),
                        diseases(),
                        MySpacing.height(20),
                        doctorList(),
                        MySpacing.height(20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: MyText.titleLarge("Today's best deals for you", fontWeight: 600)),
                            InkWell(
                              onTap: controller.seeAllProducts,
                              child: Row(
                                children: [
                                  MyText.bodyMedium(
                                    "SEE ALL PRODUCTS",
                                    fontWeight: 600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  MySpacing.width(4),
                                  Icon(LucideIcons.arrow_right, size: 14)
                                ],
                              ),
                            ),
                          ],
                        ),
                        MySpacing.height(20),
                        product()
                      ],
                    ))
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget poster() {
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          MyContainer(
              borderRadiusAll: 12,
              paddingAll: 0,
              height: 380,
              width: double.infinity,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Image.asset(Images.poster, fit: BoxFit.cover)),
          Positioned(
            right: 20,
            top: 20,
            bottom: 110,
            child: MyCard(
              width: 300,
              height: 265,
              borderRadiusAll: 12,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleLarge("Online doctors available 24/7.", fontWeight: 700),
                  MyText.bodyMedium(
                    "Get convenient, high-quality virtual care including everyday, urgent, and mental health care. Your visit could be \$0 depending on your insurance or employer benefits.",
                    fontWeight: 600,
                    muted: true,
                  ),
                  MyContainer(
                    onTap: () {},
                    color: contentTheme.primary,
                    paddingAll: 12,
                    borderRadiusAll: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyText.bodySmall("See a doctor now", fontWeight: 600, color: contentTheme.onPrimary),
                        MySpacing.width(12),
                        Icon(LucideIcons.arrow_right, color: contentTheme.onPrimary, size: 16)
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 20,
            left: 20,
            top: 330,
            child: MyContainer(
              borderRadiusAll: 12,
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceAround,
                runAlignment: WrapAlignment.center,
                children: [
                  Column(
                    children: [
                      MyText.titleLarge("130+", fontWeight: 700, color: contentTheme.primary),
                      MySpacing.height(12),
                      MyText.bodyMedium("Best Doctor", fontWeight: 600)
                    ],
                  ),
                  Column(
                    children: [
                      MyText.titleLarge("250+", fontWeight: 700, color: contentTheme.primary),
                      MySpacing.height(12),
                      MyText.bodyMedium("Professional Nurse", fontWeight: 600)
                    ],
                  ),
                  Column(
                    children: [
                      MyText.titleLarge("1200+", fontWeight: 700, color: contentTheme.primary),
                      MySpacing.height(12),
                      MyText.bodyMedium("Patient Capacity", fontWeight: 600)
                    ],
                  ),
                  Column(
                    children: [
                      MyText.titleLarge("24/7", fontWeight: 700, color: contentTheme.primary),
                      MySpacing.height(12),
                      MyText.bodyMedium("Available Doctor", fontWeight: 600)
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget features() {
    Widget featureWidget(IconData icon, String title, String subTitle) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: contentTheme.primary),
          MySpacing.width(20),
          Expanded(
            child: SizedBox(
              height: 35,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleMedium(title, fontWeight: 600, color: contentTheme.primary, maxLines: 1, overflow: TextOverflow.ellipsis),
                  MyText.labelSmall(subTitle, color: contentTheme.primary, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          )
        ],
      );
    }

    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      width: double.infinity,
      color: contentTheme.primary.withOpacity(.13),
      child: MyFlex(runAlignment: WrapAlignment.spaceAround, contentPadding: false, children: [
        MyFlexItem(sizes: 'lg-3 md-3', child: featureWidget(LucideIcons.truck, "Free Shipping", "on all orders over \$39.00")),
        MyFlexItem(sizes: 'lg-3 md-3', child: featureWidget(LucideIcons.circle_dollar_sign, "15 Days to return", "Term & Condition Apply")),
        MyFlexItem(sizes: 'lg-3 md-3', child: featureWidget(LucideIcons.shield_ellipsis, "Secure Checkout", "all orders Online Payment")),
        MyFlexItem(sizes: 'lg-3 md-3', child: featureWidget(LucideIcons.ticket_percent, "Offer & Gifts", "Coupon Code")),
      ]),
    );
  }

  Widget categories() {
    Widget categoriesWidgets(IconData icon, String title) {
      return Padding(
        padding: MySpacing.all(20),
        child: InkWell(
          onTap: () {},
          child: Row(
            children: [
              Icon(icon, size: 18),
              MySpacing.width(16),
              MyText.bodyMedium(title, fontWeight: 600),
            ],
          ),
        ),
      );
    }

    return MyContainer(
      paddingAll: 0,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyContainer(
            padding: MySpacing.all(20),
            color: contentTheme.primary,
            width: double.infinity,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: MyText.titleMedium("Categories", fontWeight: 600, color: contentTheme.onPrimary),
          ),
          categoriesWidgets(LucideIcons.briefcase_medical, "Health Care"),
          Divider(height: 0),
          categoriesWidgets(LucideIcons.settings, "First Aid"),
          Divider(height: 0),
          categoriesWidgets(LucideIcons.trophy, "Surgical Product"),
          Divider(height: 0),
          categoriesWidgets(LucideIcons.user, "Diagnostic Product"),
          Divider(height: 0),
          categoriesWidgets(LucideIcons.shopping_cart, "Laboratory Product"),
          Divider(height: 0),
          categoriesWidgets(LucideIcons.tags, "Hospital Product"),
          Divider(height: 0),
          categoriesWidgets(LucideIcons.shopping_basket, "Service & Setup"),
          Divider(height: 0),
          categoriesWidgets(LucideIcons.settings, "Food & Nutrition"),
        ],
      ),
    );
  }

  Widget diseases() {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: controller.diseases.asMap().entries.map((e) {
        int index = e.key;
        Map<String, dynamic> value = e.value;
        bool isSelected = controller.selectedDiseases == index;
        return MyContainer(
          onTap: () => controller.onSelectDiseases(index),
          paddingAll: 12,
          borderRadiusAll: 8,
          color: isSelected ? contentTheme.primary : null,
          child: MyText.bodySmall(value['name'], color: isSelected ? contentTheme.onPrimary : null),
        );
      }).toList(),
    );
  }

  Widget doctorList() {
    return SizedBox(
      height: 290,
      child: ListView.separated(
          itemCount: controller.doctorList.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            dynamic doctor = controller.doctorList[index];
            return MyContainer(
              onTap: controller.goToDetailScreen,
              paddingAll: 20,
              borderRadiusAll: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyContainer(
                      borderRadiusAll: 12,
                      paddingAll: 0,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: Image.asset(Images.avatars[index % Images.avatars.length], fit: BoxFit.cover)),
                  MyText.bodyMedium(doctor['name'], fontWeight: 600),
                  MyText.bodySmall(doctor['specialization'], muted: true),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) {
            return MySpacing.width(20);
          }),
    );
  }

  Widget product() {
    return GridView.builder(
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
                  MyStarRating(
                    rating: product['rate'],
                    activeColor: contentTheme.warning,
                  )
                ],
              ),
              MyText.bodyMedium('\$${product['price']}.00'),
            ],
          ),
        );
      },
    );
  }
}
