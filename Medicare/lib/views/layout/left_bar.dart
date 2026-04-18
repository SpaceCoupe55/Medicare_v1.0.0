import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/helpers/services/url_service.dart';
import 'package:medicare/helpers/theme/theme_customizer.dart';
import 'package:medicare/helpers/utils/my_shadow.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_card.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/images.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/widgets/custom_pop_menu.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

typedef LeftbarMenuFunction = void Function(String key);

class LeftbarObserver {
  static Map<String, LeftbarMenuFunction> observers = {};

  static attachListener(String key, LeftbarMenuFunction fn) {
    observers[key] = fn;
  }

  static detachListener(String key) {
    observers.remove(key);
  }

  static notifyAll(String key) {
    for (var fn in observers.values) {
      fn(key);
    }
  }
}

class LeftBar extends StatefulWidget {
  final bool isCondensed;

  const LeftBar({super.key, this.isCondensed = false});

  @override
  _LeftBarState createState() => _LeftBarState();
}

class _LeftBarState extends State<LeftBar> with SingleTickerProviderStateMixin, UIMixin {
  final ThemeCustomizer customizer = ThemeCustomizer.instance;

  bool isCondensed = false;

  @override
  Widget build(BuildContext context) {
    isCondensed = widget.isCondensed;
    return MyCard(
      paddingAll: 0,
      borderRadiusAll: 12,
      shadow: MyShadow(position: MyShadowPosition.centerRight, elevation: 1),
      child: AnimatedContainer(
        width: isCondensed ? 70 : 270,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: leftBarTheme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo ────────────────────────────────────────────────────────
            Padding(
              padding: MySpacing.all(12),
              child: InkWell(
                onTap: () => Get.toNamed(AppRoutes.dashboard),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isCondensed)
                      Image.asset(Images.logoSmall, height: 44, fit: BoxFit.cover),
                    if (!widget.isCondensed)
                      Flexible(
                        fit: FlexFit.loose,
                        child: MyText.displayMedium(
                          "Medicare",
                          style: GoogleFonts.raleway(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: contentTheme.primary,
                            letterSpacing: .5,
                          ),
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Menu ────────────────────────────────────────────────────────
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Obx(() {
                    final role = AppAuthController.instance.user?.role;
                    final isAdmin = role == UserRole.admin;
                    final isDoctor = role == UserRole.doctor;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MySpacing.height(12),

                        // ── GROUP: Main ──────────────────────────────────
                        LabelWidget(isCondensed: isCondensed, label: "Main"),
                        NavigationItem(
                          iconData: LucideIcons.layout_dashboard,
                          title: "Dashboard",
                          isCondensed: isCondensed,
                          route: AppRoutes.dashboard,
                        ),
                        NavigationItem(
                          iconData: LucideIcons.chart_bar,
                          title: "Reports",
                          isCondensed: isCondensed,
                          route: AppRoutes.reports,
                        ),

                        MySpacing.height(8),

                        // ── GROUP: People ────────────────────────────────
                        LabelWidget(isCondensed: isCondensed, label: "People"),
                        MenuWidget(
                          iconData: LucideIcons.user_plus,
                          isCondensed: isCondensed,
                          title: "Patients",
                          children: [
                            MenuItem(title: "List", isCondensed: isCondensed, route: AppRoutes.patientList),
                            MenuItem(title: "Add New", isCondensed: isCondensed, route: AppRoutes.patientAdd),
                          ],
                        ),
                        MenuWidget(
                          iconData: LucideIcons.briefcase_medical,
                          isCondensed: isCondensed,
                          title: "Doctors",
                          children: [
                            MenuItem(title: "List", isCondensed: isCondensed, route: AppRoutes.doctorList),
                            if (isAdmin)
                              MenuItem(title: "Add New", isCondensed: isCondensed, route: AppRoutes.doctorAdd),
                          ],
                        ),

                        MySpacing.height(8),

                        // ── GROUP: Operations ────────────────────────────
                        LabelWidget(isCondensed: isCondensed, label: "Operations"),
                        MenuWidget(
                          iconData: LucideIcons.notepad_text,
                          isCondensed: isCondensed,
                          title: "Appointments",
                          children: [
                            MenuItem(title: "List", isCondensed: isCondensed, route: AppRoutes.appointmentList),
                            MenuItem(title: "Book New", isCondensed: isCondensed, route: AppRoutes.appointmentBook),
                            MenuItem(title: "Schedule", isCondensed: isCondensed, route: AppRoutes.appointmentSchedule),
                          ],
                        ),
                        MenuWidget(
                          iconData: LucideIcons.tablets,
                          isCondensed: isCondensed,
                          title: "Pharmacy",
                          children: [
                            MenuItem(title: "Inventory", isCondensed: isCondensed, route: AppRoutes.pharmacyList),
                            MenuItem(title: "Cart", isCondensed: isCondensed, route: AppRoutes.pharmacyCart),
                            MenuItem(title: "Checkout", isCondensed: isCondensed, route: AppRoutes.pharmacyCheckout),
                          ],
                        ),
                        NavigationItem(
                          iconData: LucideIcons.message_square_text,
                          title: "SMS / Messaging",
                          isCondensed: isCondensed,
                          route: AppRoutes.chat,
                        ),

                        // ── GROUP: My Portal (doctor only) ───────────────
                        if (isDoctor) ...[
                          MySpacing.height(8),
                          LabelWidget(isCondensed: isCondensed, label: "My Portal"),
                          NavigationItem(
                            iconData: LucideIcons.layout_dashboard,
                            title: "My Dashboard",
                            isCondensed: isCondensed,
                            route: AppRoutes.doctorPortal,
                          ),
                        ],

                        // ── GROUP: System (admin only) ───────────────────
                        if (isAdmin) ...[
                          MySpacing.height(8),
                          LabelWidget(isCondensed: isCondensed, label: "System"),
                          NavigationItem(
                            iconData: LucideIcons.settings,
                            title: "Settings",
                            isCondensed: isCondensed,
                            route: AppRoutes.settings,
                          ),
                        ],

                        MySpacing.height(20),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sidebar widget classes ─────────────────────────────────────────────

class LabelWidget extends StatelessWidget {
  final bool isCondensed;
  final String label;

  const LabelWidget({super.key, required this.isCondensed, required this.label});

  @override
  Widget build(BuildContext context) {
    if (isCondensed) return const SizedBox.shrink();
    return Container(
      margin: MySpacing.fromLTRB(16, 0, 16, 8),
      child: MyText.bodySmall(label, muted: true, fontWeight: 600),
    );
  }
}

class MenuWidget extends StatefulWidget {
  final IconData iconData;
  final String title;
  final bool isCondensed;
  final bool active;
  final List<MenuItem> children;

  const MenuWidget({
    super.key,
    required this.iconData,
    required this.title,
    this.isCondensed = false,
    this.active = false,
    this.children = const [],
  });

  @override
  _MenuWidgetState createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> with UIMixin, SingleTickerProviderStateMixin {
  bool isHover = false;
  bool isActive = false;
  late Animation<double> _iconTurns;
  late AnimationController _controller;
  bool popupShowing = true;
  Function? hideFn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _iconTurns = _controller.drive(Tween<double>(begin: 0.0, end: 0.5).chain(CurveTween(curve: Curves.easeIn)));
    LeftbarObserver.attachListener(widget.title, onChangeMenuActive);
  }

  void onChangeMenuActive(String key) {
    if (key != widget.title) onChangeExpansion(false);
  }

  void onChangeExpansion(value) {
    isActive = value;
    if (isActive) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var route = UrlService.getCurrentUrl();
    isActive = widget.children.any((element) => element.route == route);
    onChangeExpansion(isActive);
    if (hideFn != null) hideFn!();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCondensed) {
      return CustomPopupMenu(
        backdrop: true,
        show: popupShowing,
        hideFn: (hide) => hideFn = hide,
        onChange: (value) => popupShowing = value,
        placement: CustomPopupMenuPlacement.right,
        menu: MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (event) => setState(() => isHover = true),
          onExit: (event) => setState(() => isHover = false),
          child: MyContainer.transparent(
            margin: MySpacing.fromLTRB(16, 0, 16, 8),
            color: isActive || isHover ? leftBarTheme.activeItemBackground : Colors.transparent,
            padding: MySpacing.all(8),
            borderRadiusAll: 12,
            child: Center(
              child: Icon(
                widget.iconData,
                color: (isHover || isActive) ? leftBarTheme.activeItemColor : leftBarTheme.onBackground,
                size: 20,
              ),
            ),
          ),
        ),
        menuBuilder: (_) => MyContainer(
          paddingAll: 8,
          borderRadiusAll: 12,
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: widget.children,
          ),
        ),
      );
    } else {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (event) => setState(() => isHover = true),
        onExit: (event) => setState(() => isHover = false),
        child: MyContainer.transparent(
          margin: MySpacing.fromLTRB(24, 0, 16, 0),
          paddingAll: 0,
          child: ListTileTheme(
            contentPadding: const EdgeInsets.all(0),
            dense: true,
            horizontalTitleGap: 0.0,
            child: ExpansionTile(
              tilePadding: MySpacing.zero,
              initiallyExpanded: isActive,
              maintainState: true,
              onExpansionChanged: (value) {
                LeftbarObserver.notifyAll(widget.title);
                onChangeExpansion(value);
              },
              trailing: RotationTransition(
                turns: _iconTurns,
                child: Icon(LucideIcons.chevron_down, size: 18, color: leftBarTheme.onBackground),
              ),
              iconColor: leftBarTheme.activeItemColor,
              childrenPadding: MySpacing.x(12),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    widget.iconData,
                    size: 20,
                    color: isHover || isActive ? leftBarTheme.activeItemColor : leftBarTheme.onBackground,
                  ),
                  MySpacing.width(18),
                  Expanded(
                    child: MyText.labelLarge(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      color: isHover || isActive ? leftBarTheme.activeItemColor : leftBarTheme.onBackground,
                    ),
                  ),
                ],
              ),
              collapsedBackgroundColor: Colors.transparent,
              shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.transparent)),
              backgroundColor: Colors.transparent,
              children: widget.children,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    LeftbarObserver.detachListener(widget.title);
    super.dispose();
  }
}

class MenuItem extends StatefulWidget {
  final IconData? iconData;
  final String title;
  final bool isCondensed;
  final String? route;

  const MenuItem({
    super.key,
    this.iconData,
    required this.title,
    this.isCondensed = false,
    this.route,
  });

  @override
  _MenuItemState createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> with UIMixin {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    bool isActive = UrlService.getCurrentUrl() == widget.route;
    return GestureDetector(
      onTap: () {
        if (widget.route != null) Get.toNamed(widget.route!);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (event) => setState(() => isHover = true),
        onExit: (event) => setState(() => isHover = false),
        child: MyContainer.transparent(
          margin: MySpacing.fromLTRB(4, 0, 8, 4),
          color: isActive || isHover ? leftBarTheme.activeItemBackground : Colors.transparent,
          width: MediaQuery.of(context).size.width,
          padding: MySpacing.xy(18, 7),
          borderRadiusAll: 12,
          child: MyText.bodySmall(
            "${widget.isCondensed ? "-" : "- "}  ${widget.title}",
            overflow: TextOverflow.clip,
            maxLines: 1,
            textAlign: TextAlign.left,
            fontSize: 12.5,
            color: isActive || isHover ? leftBarTheme.activeItemColor : leftBarTheme.onBackground,
            fontWeight: isActive || isHover ? 600 : 500,
          ),
        ),
      ),
    );
  }
}

class NavigationItem extends StatefulWidget {
  final IconData? iconData;
  final String title;
  final bool isCondensed;
  final String? route;

  const NavigationItem({
    super.key,
    this.iconData,
    required this.title,
    this.isCondensed = false,
    this.route,
  });

  @override
  _NavigationItemState createState() => _NavigationItemState();
}

class _NavigationItemState extends State<NavigationItem> with UIMixin {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    bool isActive = UrlService.getCurrentUrl() == widget.route;
    return GestureDetector(
      onTap: () {
        if (widget.route != null) Get.toNamed(widget.route!);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (event) => setState(() => isHover = true),
        onExit: (event) => setState(() => isHover = false),
        child: MyContainer(
          margin: MySpacing.fromLTRB(16, 0, 16, 8),
          color: isActive || isHover ? leftBarTheme.activeItemBackground : Colors.transparent,
          paddingAll: 8,
          borderRadiusAll: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.iconData != null)
                Center(
                  child: Icon(
                    widget.iconData,
                    color: (isHover || isActive) ? leftBarTheme.activeItemColor : leftBarTheme.onBackground,
                    size: 20,
                  ),
                ),
              if (!widget.isCondensed) Flexible(fit: FlexFit.loose, child: MySpacing.width(16)),
              if (!widget.isCondensed)
                Expanded(
                  flex: 3,
                  child: MyText.labelLarge(
                    widget.title,
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    color: isActive || isHover ? leftBarTheme.activeItemColor : leftBarTheme.onBackground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
