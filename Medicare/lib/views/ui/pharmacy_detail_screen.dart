import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/pharmacy_detail_controller.dart';
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
import 'package:medicare/views/ui/carousels_screen.dart';

class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({super.key});

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> with UIMixin {
  PharmacyDetailController controller = Get.put(PharmacyDetailController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'pharmacy_detail_controller',
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
                      "Detail",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Detail', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyContainer(
                      borderRadiusAll: 12,
                      paddingAll: 20,
                      child: MyFlex(contentPadding: false, children: [
                        MyFlexItem(sizes: 'lg-4.5', child: productImageSlider()),
                        MyFlexItem(sizes: 'lg-7.5', child: productDetail()),
                      ]),
                    ),
                    MySpacing.height(20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [MyText.titleMedium("Related Products :", fontWeight: 600), MySpacing.height(20), relatedProducts()],
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget productImageSlider() {
    List<Widget> buildPageIndicatorStatic() {
      List<Widget> list = [];
      for (int i = 0; i < controller.animatedCarouselSize; i++) {
        list.add(i == controller.selectedAnimatedCarousel ? indicator(true) : indicator(false));
      }
      return list;
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        MyContainer.bordered(
          height: 300,
          borderRadiusAll: 12,
          paddingAll: 20,
          child: PageView(
            pageSnapping: true,
            scrollBehavior: AppScrollBehavior(),
            physics: ClampingScrollPhysics(),
            controller: controller.animatedPageController,
            onPageChanged: controller.onChangeAnimatedCarousel,
            children: <Widget>[
              MyContainer(
                borderRadiusAll: 12,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                paddingAll: 0,
                child: Image.asset('assets/images/products/product_1.jpg', fit: BoxFit.fill),
              ),
              MyContainer(
                borderRadiusAll: 12,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                paddingAll: 0,
                child: Image.asset('assets/images/products/product_2.jpg', fit: BoxFit.fill),
              ),
              MyContainer(
                borderRadiusAll: 12,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                paddingAll: 0,
                child: Image.asset('assets/images/products/product_3.jpg', fit: BoxFit.fill),
              ),
            ],
          ),
        ),

        Positioned(
            bottom: 8,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: buildPageIndicatorStatic())),
      ],
    );
  }

  Widget indicator(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInToLinear,
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: 8,
      decoration: BoxDecoration(
        color: isActive ? contentTheme.primary : contentTheme.secondary,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    );
  }

  Widget productDetail() {
    return SizedBox(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleLarge("Medicine Box", fontWeight: 600, muted: true),
          MyText.bodyMedium("\$99.00", fontWeight: 700, muted: true),
          Row(
            children: [
              MyStarRating(rating: 4.5, activeColor: contentTheme.primary),
              MySpacing.width(8),
              MyText.bodyMedium("(100 Reviews)", fontWeight: 600, xMuted: true)
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.bodyMedium("Overview :", fontWeight: 600, muted: true),
              MySpacing.height(8),
              MyText.bodySmall(controller.dummyTexts[0], muted: true),
            ],
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText.bodyMedium("Quantity:"),
              MySpacing.width(12),
              MyContainer.bordered(
                paddingAll: 8,
                borderRadiusAll: 8,
                onTap: () => controller.decrementQuantity(),
                child: Icon(LucideIcons.minus, size: 16),
              ),
              MySpacing.width(12),
              MyContainer(
                  paddingAll: 0,
                  height: 32,
                  width: 32,
                  borderRadiusAll: 8,
                  color: contentTheme.primary,
                  child: Center(child: MyText.bodyMedium(controller.quantity.toString(), color: contentTheme.onPrimary))),
              MySpacing.width(12),
              MyContainer.bordered(
                paddingAll: 8,
                borderRadiusAll: 8,
                onTap: () => controller.incrementQuantity(),
                child: Icon(LucideIcons.plus, size: 16),
              ),
            ],
          ),
          Row(
            children: [
              MyContainer(
                onTap: controller.shopNow,
                borderRadiusAll: 6,
                padding: MySpacing.xy(12, 8),
                color: contentTheme.primary,
                child: MyText.bodySmall("Shop Now", color: contentTheme.onPrimary, fontWeight: 600),
              ),
              MySpacing.width(20),
              MyContainer(
                onTap: controller.addToCart,
                borderRadiusAll: 6,
                padding: MySpacing.xy(12, 8),
                color: contentTheme.secondary,
                child: MyText.bodySmall("Add to cart", color: contentTheme.onSecondary, fontWeight: 600),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget relatedProducts() {
    return SizedBox(
      height: 400,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: controller.products.length,
        itemBuilder: (context, index) {
          dynamic product = controller.products[index];
          return MyContainer(
            paddingAll: 20,
            borderRadiusAll: 12,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyContainer(
                  height: 300,
                  width: 300,
                  paddingAll: 0,
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
        separatorBuilder: (context, index) {
          return MySpacing.width(20);
        },
      ),
    );
  }
}
