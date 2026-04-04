import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/helpers/localizations/language.dart';
import 'package:medicare/helpers/theme/app_notifire.dart';
import 'package:medicare/helpers/theme/app_style.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/theme/theme_customizer.dart';
import 'package:medicare/helpers/utils/my_shadow.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_card.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_dashed_divider.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/controller/app_notification_controller.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/notification_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/widgets/custom_pop_menu.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

// ── Avatar helpers ────────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _avatarColor(String name) {
  const palette = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
    Color(0xFF7E57C2),
    Color(0xFF26C6DA),
    Color(0xFF66BB6A),
    Color(0xFFF57C00),
  ];
  return palette[name.hashCode.abs() % palette.length];
}

Widget _avatarWidget(String name, String? avatarUrl, double size) {
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsCircle(name, size),
      ),
    );
  }
  return _initialsCircle(name, size);
}

Widget _initialsCircle(String name, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: _avatarColor(name), shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Text(
      _initials(name),
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.38,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with SingleTickerProviderStateMixin, UIMixin {
  Function? languageHideFn;
  Function? notificationHideFn;

  @override
  Widget build(BuildContext context) {
    return MyCard(
      shadow: MyShadow(position: MyShadowPosition.bottomRight, elevation: 1),
      height: 60,
      borderRadiusAll: 12,
      padding: MySpacing.x(24),
      color: topBarTheme.background.withAlpha(246),
      child: Row(
        children: [
          InkWell(
              splashColor: theme.colorScheme.onSurface,
              highlightColor: theme.colorScheme.onSurface,
              onTap: () {
                ThemeCustomizer.toggleLeftBarCondensed();
              },
              child: Icon(
                LucideIcons.menu,
                color: topBarTheme.onBackground,
              )),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    ThemeCustomizer.setTheme(ThemeCustomizer.instance.theme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
                  },
                  child: Icon(
                    ThemeCustomizer.instance.theme == ThemeMode.dark ? LucideIcons.sun : LucideIcons.moon,
                    size: 18,
                    color: topBarTheme.onBackground,
                  ),
                ),
                MySpacing.width(12),
                CustomPopupMenu(
                  backdrop: true,
                  hideFn: (hide) => languageHideFn = hide,
                  onChange: (_) {},
                  offsetX: -36,
                  menu: Padding(
                    padding: MySpacing.xy(8, 8),
                    child: Center(
                      child: ClipRRect(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        borderRadius: BorderRadius.circular(2),
                        child: Image.asset(
                          "assets/lang/${ThemeCustomizer.instance.currentLanguage.locale.languageCode}.jpg",
                          width: 24,
                          height: 18,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  menuBuilder: (_) => buildLanguageSelector(),
                ),
                MySpacing.width(6),
                CustomPopupMenu(
                  backdrop: true,
                  hideFn: (hide) => notificationHideFn = hide,
                  onChange: (_) {},
                  offsetX: -120,
                  menu: Padding(
                    padding: MySpacing.xy(8, 8),
                    child: Center(
                      child: Obx(() {
                        final count = AppNotificationController.instance.unreadCount;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(LucideIcons.bell, size: 18),
                            if (count > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  menuBuilder: (_) => buildNotifications(),
                ),
                MySpacing.width(4),
                CustomPopupMenu(
                  backdrop: true,
                  onChange: (_) {},
                  offsetX: -60,
                  offsetY: 8,
                  menu: Obx(() {
                    final ctrl = AppAuthController.instance;
                    final name = ctrl.userName;
                    final avatarUrl = ctrl.userAvatarUrl;
                    return Padding(
                      padding: MySpacing.xy(8, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _avatarWidget(name, avatarUrl, 28),
                          MySpacing.width(8),
                          MyText.labelLarge(name),
                        ],
                      ),
                    );
                  }),
                  menuBuilder: (_) => buildAccountMenu(),
                  hideFn: (hide) => languageHideFn = hide,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildLanguageSelector() {
    return MyContainer.bordered(
      padding: MySpacing.xy(8, 8),
      width: 125,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: Language.languages
            .map((language) => MyButton.text(
                  padding: MySpacing.xy(8, 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  splashColor: contentTheme.onBackground.withAlpha(20),
                  onPressed: () async {
                    languageHideFn?.call();
                    await Provider.of<AppNotifier>(context, listen: false).changeLanguage(language, notify: true);
                    ThemeCustomizer.notify();
                    setState(() {});
                  },
                  child: Row(
                    children: [
                      ClipRRect(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          borderRadius: BorderRadius.circular(2),
                          child: Image.asset(
                            "assets/lang/${language.locale.languageCode}.jpg",
                            width: 18,
                            height: 14,
                            fit: BoxFit.cover,
                          )),
                      MySpacing.width(8),
                      MyText.labelMedium(language.languageName)
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget buildNotifications() {
    return Obx(() {
      final ctrl = AppNotificationController.instance;
      final items = ctrl.notifications;

      return MyContainer.bordered(
        paddingAll: 0,
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: MySpacing.xy(16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.titleMedium('Notifications', fontWeight: 600),
                  if (ctrl.unreadCount > 0)
                    MyButton.text(
                      onPressed: ctrl.markAllAsRead,
                      borderRadiusAll: 6,
                      padding: MySpacing.xy(8, 4),
                      splashColor: contentTheme.primary.withAlpha(28),
                      child: MyText.labelSmall('Mark all as read',
                          color: contentTheme.primary),
                    ),
                ],
              ),
            ),
            MyDashedDivider(
                height: 1,
                color: theme.dividerColor,
                dashSpace: 4,
                dashWidth: 6),

            // ── List ────────────────────────────────────────────────────────
            if (items.isEmpty)
              Padding(
                padding: MySpacing.xy(16, 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.bell_off,
                          size: 32,
                          color: contentTheme.secondary.withAlpha(100)),
                      MySpacing.height(8),
                      MyText.bodySmall('No notifications yet', muted: true),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, thickness: 0.5, color: theme.dividerColor),
                  itemBuilder: (_, i) =>
                      _notificationTile(items[i]),
                ),
              ),

            // ── Footer ──────────────────────────────────────────────────────
            if (items.isNotEmpty) ...[
              MyDashedDivider(
                  height: 1,
                  color: theme.dividerColor,
                  dashSpace: 4,
                  dashWidth: 6),
              Padding(
                padding: MySpacing.xy(12, 6),
                child: MyText.labelSmall(
                  '${ctrl.unreadCount} unread · ${items.length} total',
                  muted: true,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Color _borderColorForType(String type) {
    switch (type) {
      case 'appointment_booked':
        return Colors.blue;
      case 'appointment_cancelled':
        return Colors.red;
      case 'appointment_reminder':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _notificationTile(NotificationModel n) {
    final unreadBg = contentTheme.primary.withAlpha(18);
    return InkWell(
      onTap: () async {
        // Mark as read
        if (!n.read) await AppNotificationController.instance.markAsRead(n.id);
        // Navigate to related page
        if (n.type.startsWith('appointment')) {
          notificationHideFn?.call();
          Get.toNamed(AppRoutes.appointmentList);
        } else {
          notificationHideFn?.call();
        }
      },
      child: Container(
        color: n.read ? null : unreadBg,
        padding: MySpacing.xy(12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coloured left accent
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _borderColorForType(n.type),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            MySpacing.width(10),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: MyText.labelMedium(n.title,
                            fontWeight: n.read ? 500 : 700,
                            overflow: TextOverflow.ellipsis),
                      ),
                      MySpacing.width(8),
                      MyText.bodySmall(_timeAgo(n.createdAt),
                          muted: true, fontSize: 10),
                    ],
                  ),
                  MySpacing.height(2),
                  MyText.bodySmall(n.body,
                      muted: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Unread dot
            if (!n.read) ...[
              MySpacing.width(6),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildAccountMenu() {
    return MyContainer.bordered(
      paddingAll: 0,
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: MySpacing.xy(8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyButton(
                  onPressed: () {
                    Get.toNamed('/admin/setting');
                    setState(() {});
                  },
                  // onPressed: () =>
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  borderRadiusAll: AppStyle.buttonRadius.medium,
                  padding: MySpacing.xy(8, 4),
                  splashColor: theme.colorScheme.onSurface.withAlpha(20),
                  backgroundColor: Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 14,
                        color: contentTheme.onBackground,
                      ),
                      MySpacing.width(8),
                      MyText.labelMedium(
                        "My Profile",
                        fontWeight: 600,
                      )
                    ],
                  ),
                ),
                MySpacing.height(4),
                MyButton(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () {
                    Get.toNamed('/admin/setting');
                    setState(() {});
                  },
                  borderRadiusAll: AppStyle.buttonRadius.medium,
                  padding: MySpacing.xy(8, 4),
                  splashColor: theme.colorScheme.onSurface.withAlpha(20),
                  backgroundColor: Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.pencil,
                        size: 14,
                        color: contentTheme.onBackground,
                      ),
                      MySpacing.width(8),
                      MyText.labelMedium(
                        "Edit Profile",
                        fontWeight: 600,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
          ),
          Padding(
            padding: MySpacing.xy(8, 8),
            child: MyButton(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () {
                languageHideFn?.call();
                AppAuthController.instance.signOut();
              },
              borderRadiusAll: AppStyle.buttonRadius.medium,
              padding: MySpacing.xy(8, 4),
              splashColor: contentTheme.danger.withAlpha(28),
              backgroundColor: Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    LucideIcons.log_out,
                    size: 14,
                    color: contentTheme.danger,
                  ),
                  MySpacing.width(8),
                  MyText.labelMedium(
                    "Log out",
                    fontWeight: 600,
                    color: contentTheme.danger,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
