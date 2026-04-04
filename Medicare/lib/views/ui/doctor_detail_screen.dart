import 'package:medicare/controller/ui/doctor_detail_controller.dart';
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
import 'package:medicare/images.dart';
import 'package:medicare/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({super.key});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> with UIMixin {
  DoctorDetailController controller = Get.put(DoctorDetailController());
  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'admin_doctor_detail_controller',
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
                      "Doctor Detail",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Admin'),
                        MyBreadcrumbItem(name: 'Doctor Detail', active: true),
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
                        sizes: 'lg-4',
                        child: Column(
                          children: [doctorProfile(), MySpacing.height(24), about(), MySpacing.height(24), workExpertise()],
                        )),
                    MyFlexItem(
                        sizes: 'lg-8',
                        child: Column(
                          children: [
                            address(),
                            MySpacing.height(24),
                            education(),
                            MySpacing.height(24),
                            experience(),
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

  Widget doctorProfile() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Row(
        children: [
          MyContainer(
            height: 150,
            width: 150,
            paddingAll: 0,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            borderRadiusAll: 12,
            child: Image.asset(Images.avatars[4], fit: BoxFit.cover),
          ),
          MySpacing.width(20),
          Expanded(
            child: SizedBox(
              height: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.bodyMedium("Dr. Nathan Churchill", fontWeight: 600, muted: true, overflow: TextOverflow.ellipsis),
                  MyText.bodySmall("MBBS, MS - General Surgery, General Physician", fontWeight: 600, muted: true, overflow: TextOverflow.ellipsis),
                  MyText.bodySmall("12 Year Experience", fontWeight: 600, muted: true, overflow: TextOverflow.ellipsis),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MyStarRating(activeColor: contentTheme.warning),
                      MySpacing.width(8),
                      Flexible(child: MyText.bodySmall("3736 Reviews", fontWeight: 600, xMuted: true, overflow: TextOverflow.ellipsis)),
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

  Widget about() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("About Me", fontWeight: 600),
          MySpacing.height(20),
          MyText.bodySmall(controller.dummyTexts[0], muted: true),
          MySpacing.height(20),
          MyText.bodyMedium("Email", fontWeight: 600),
          MySpacing.height(8),
          MyText.bodySmall("nathanchurchill@gmail.com"),
          MySpacing.height(20),
          MyText.bodyMedium("Phone", fontWeight: 600),
          MySpacing.height(8),
          MyText.bodySmall("+91 1234567890"),
        ],
      ),
    );
  }

  Widget address() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Address", fontWeight: 600),
          MySpacing.height(20),
          MyText.bodySmall("Parcela José María Villegas, 95 Puerta 539, Valdemoro, Mur 68809", muted: true),
        ],
      ),
    );
  }

  Widget workExpertise() {
    Widget progress(Color color, String title, String percentage, double value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.bodyMedium(title, fontWeight: 600, muted: true),
              MyText.labelMedium(percentage, fontWeight: 600, muted: true),
            ],
          ),
          MySpacing.height(8),
          LinearProgressIndicator(value: value, color: color, minHeight: 8, borderRadius: BorderRadius.circular(8))
        ],
      );
    }

    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Work Expertise", fontWeight: 600),
          MySpacing.height(20),
          progress(contentTheme.danger, "OPD", "50%", .4),
          MySpacing.height(20),
          progress(contentTheme.info, "Operations", "85%", .85),
          MySpacing.height(20),
          progress(contentTheme.primary, "Patient visit", "20%", .2),
          MySpacing.height(20),
        ],
      ),
    );
  }

  Widget education() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Education", fontWeight: 600),
          MySpacing.height(20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(LucideIcons.dot),
              MySpacing.width(4),
              MyText.bodySmall("M.B.B.S.Queensbury campus", muted: true),
            ],
          ),
          MySpacing.height(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.dot),
              MySpacing.width(4),
              Expanded(child: MyText.bodySmall("M.D. of Medicine	University of Wyoming", muted: true)),
            ],
          ),
          MySpacing.height(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.dot),
              MySpacing.width(4),
              Expanded(child: MyText.bodySmall("SPINAL FELLOWSHIP Dr. John Adam, Allegimeines Krakenhaus, Schwerin, Germany.", muted: true)),
            ],
          ),
          MySpacing.height(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.dot),
              MySpacing.width(4),
              Expanded(child: MyText.bodySmall("Fellowship in Endoscopic Spine Surgery Phoenix, USA.", muted: true)),
            ],
          )
        ],
      ),
    );
  }

  Widget experience() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Experience", fontWeight: 600),
          MySpacing.height(20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.dot),
              MySpacing.width(4),
              Expanded(child: MyText.bodySmall("One year rotatory internship from April-2009 to march-2010 at B. J. Medical College, US", muted: true)),
            ],
          ),
          MySpacing.height(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.dot),
              MySpacing.width(4),
              Expanded(child: MyText.bodySmall("Three year residency at V.S. General Hospital as a resident in orthopedics from April - 2008 to April - 2011.", muted: true)),
            ],
          ),
          MySpacing.height(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.dot),
              MySpacing.width(4),
              Expanded(child: MyText.bodySmall("I have worked as a part time physiotherapist in Apang manav mandal from 1st june 2004 to 31st jan 2005.", muted: true)),
            ],
          ),
          MySpacing.height(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.dot),
              MySpacing.width(4),
              Expanded(
                  child: MyText.bodySmall("Clinical and Research fellowship in Scoliosis at Shaurashtra University and Medical Centre (KUMC) , Krishna Hospital , Canada from April 2013 to June 2013.",
                      muted: true)),
            ],
          ),
          MySpacing.height(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.dot),
              MySpacing.width(4),
              Expanded(child: MyText.bodySmall("Consultant Orthopedics Surgeon Jalna 2 years.", muted: true)),
            ],
          ),
        ],
      ),
    );
  }
}
