import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/views/auth/forgot_password_screen.dart';
import 'package:medicare/views/auth/login_screen.dart';
import 'package:medicare/views/auth/register_account_screen.dart';
import 'package:medicare/views/auth/reset_password_screen.dart';
import 'package:medicare/views/ui/appointment_book_screen.dart';
import 'package:medicare/views/ui/appointment_edit_screen.dart';
import 'package:medicare/views/ui/appointment_list_screen.dart';
import 'package:medicare/views/ui/appointment_scheduling_screen.dart';
import 'package:medicare/views/ui/basic_table_screen.dart';
import 'package:medicare/views/ui/buttons_screen.dart';
import 'package:medicare/views/ui/cards_screen.dart';
import 'package:medicare/views/ui/carousels_screen.dart';
import 'package:medicare/views/ui/chat_screen.dart';
import 'package:medicare/views/ui/dashboard_screen.dart';
import 'package:medicare/views/ui/dialogs_screen.dart';
import 'package:medicare/views/ui/doctor_add_screen.dart';
import 'package:medicare/views/ui/doctor_detail_screen.dart';
import 'package:medicare/views/ui/doctor_edit_screen.dart';
import 'package:medicare/views/ui/doctor_list_screen.dart';
import 'package:medicare/views/ui/drag_n_drop_screen.dart';
import 'package:medicare/views/ui/error_pages/coming_soon_screen.dart';
import 'package:medicare/views/ui/error_pages/error_404_screen.dart';
import 'package:medicare/views/ui/error_pages/error_500_screen.dart';
import 'package:medicare/views/ui/extra_pages/faqs_screen.dart';
import 'package:medicare/views/ui/extra_pages/pricing_screen.dart';
import 'package:medicare/views/ui/extra_pages/time_line_screen.dart';
import 'package:medicare/views/ui/forms/basic_input_screen.dart';
import 'package:medicare/views/ui/forms/custom_option_screen.dart';
import 'package:medicare/views/ui/forms/editor_screen.dart';
import 'package:medicare/views/ui/forms/file_upload_screen.dart';
import 'package:medicare/views/ui/forms/mask_screen.dart';
import 'package:medicare/views/ui/forms/slider_screen.dart';
import 'package:medicare/views/ui/forms/validation_screen.dart';
import 'package:medicare/views/ui/home_screen.dart';
import 'package:medicare/views/ui/loaders_screen.dart';
import 'package:medicare/views/ui/modal_screen.dart';
import 'package:medicare/views/ui/notification_screen.dart';
import 'package:medicare/views/ui/patient_add_screen.dart';
import 'package:medicare/views/ui/patient_detail_screen.dart';
import 'package:medicare/views/ui/patient_edit_screen.dart';
import 'package:medicare/views/ui/patient_list_screen.dart';
import 'package:medicare/views/ui/pharmacy_cart_screen.dart';
import 'package:medicare/views/ui/pharmacy_checkout_screen.dart';
import 'package:medicare/views/ui/pharmacy_detail_screen.dart';
import 'package:medicare/views/ui/pharmacy_list_screen.dart';
import 'package:medicare/views/ui/setting_screen.dart';
import 'package:medicare/views/ui/tabs_screen.dart';
import 'package:medicare/views/ui/toast_message_screen.dart';
import 'package:medicare/views/ui/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Redirects unauthenticated users to the login page.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (FirebaseAuth.instance.currentUser != null) return null;
    final next = Uri.encodeComponent(route ?? '/');
    return RouteSettings(name: '/auth/login?next=$next');
  }
}

/// Redirects users whose role is not in [allowedRoles] back to the dashboard.
/// Must be placed after [AuthMiddleware] in the middleware list.
class RoleMiddleware extends GetMiddleware {
  final List<UserRole> allowedRoles;
  RoleMiddleware(this.allowedRoles);

  @override
  RouteSettings? redirect(String? route) {
    final user = AppAuthController.instance.user;
    // If the user doc hasn't loaded yet, let through — the page handles loading state.
    if (user == null) return null;
    if (!allowedRoles.contains(user.role)) return const RouteSettings(name: '/');
    return null;
  }
}

// Convenience shorthand middleware lists.
List<GetMiddleware> _auth() => [AuthMiddleware()];
List<GetMiddleware> _adminOnly() => [AuthMiddleware(), RoleMiddleware([UserRole.admin])];
List<GetMiddleware> _clinicalStaff() => [
      AuthMiddleware(),
      RoleMiddleware([UserRole.admin, UserRole.doctor, UserRole.nurse]),
    ];
List<GetMiddleware> _pharmacyStaff() => [
      AuthMiddleware(),
      RoleMiddleware([UserRole.admin, UserRole.receptionist]),
    ];

getPageRoute() {
  var routes = [
    // ── Root & Dashboard ────────────────────────────────────────────────────
    GetPage(name: '/', page: () => const DashboardScreen(), middlewares: _auth()),
    GetPage(name: '/dashboard', page: () => const DashboardScreen(), middlewares: _auth()),
    GetPage(name: '/home', page: () => const HomeScreen(), middlewares: _auth()),

    // ── Auth (no guard needed) ───────────────────────────────────────────────
    GetPage(name: '/auth/login', page: () => const LoginScreen()),
    GetPage(name: '/auth/register_account', page: () => const RegisterAccountScreen()),
    GetPage(name: '/auth/forgot_password', page: () => const ForgotPasswordScreen()),
    GetPage(name: '/auth/reset_password', page: () => const ResetPasswordScreen()),

    // ── Settings — admin only ───────────────────────────────────────────────
    GetPage(name: '/admin/setting', page: () => const SettingScreen(), middlewares: _adminOnly()),

    // ── Wallet / Home ───────────────────────────────────────────────────────
    GetPage(name: '/admin/wallet', page: () => const WalletScreen(), middlewares: _auth()),

    // ── Pharmacy — admin or receptionist ────────────────────────────────────
    GetPage(name: '/pharmacy_list', page: () => const PharmacyListScreen(), middlewares: _pharmacyStaff()),
    GetPage(name: '/detail', page: () => const PharmacyDetailScreen(), middlewares: _pharmacyStaff()),
    GetPage(name: '/cart', page: () => const PharmacyCartScreen(), middlewares: _pharmacyStaff()),
    GetPage(name: '/pharmacy_checkout', page: () => const PharmacyCheckoutScreen(), middlewares: _pharmacyStaff()),

    // ── Appointments — admin, doctor, nurse ──────────────────────────────────
    GetPage(name: '/appointment_book', page: () => const AppointmentBookScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/appointment_edit', page: () => const AppointmentEditScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/admin/appointment_edit', page: () => const AppointmentEditScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/admin/appointment_book', page: () => const AppointmentBookScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/admin/appointment_list', page: () => const AppointmentListScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/admin/appointment_scheduling', page: () => const AppointmentSchedulingScreen(), middlewares: _clinicalStaff()),

    // ── Doctors — add is admin only; list/detail/edit for clinical staff ─────
    GetPage(name: '/admin/doctor/add', page: () => const DoctorAddScreen(), middlewares: _adminOnly()),
    GetPage(name: '/admin/doctor/list', page: () => const DoctorListScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/admin/doctor/detail', page: () => const DoctorDetailScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/admin/doctor/edit', page: () => const DoctorEditScreen(), middlewares: _clinicalStaff()),

    // ── Patients — admin, doctor, nurse ─────────────────────────────────────
    GetPage(name: '/admin/patient/list', page: () => const PatientListScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/admin/patient/add', page: () => const PatientAddScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/admin/patient/edit', page: () => const PatientEditScreen(), middlewares: _clinicalStaff()),
    GetPage(name: '/admin/patient/detail', page: () => const PatientDetailScreen(), middlewares: _clinicalStaff()),

    // ── Chat ─────────────────────────────────────────────────────────────────
    GetPage(name: '/chat', page: () => const ChatScreen(), middlewares: _auth()),

    // ── Widget / form / table demos (any authenticated user) ─────────────────
    GetPage(name: '/widget/buttons', page: () => const ButtonsScreen(), middlewares: _auth()),
    GetPage(name: '/widget/toast', page: () => const ToastMessageScreen(), middlewares: _auth()),
    GetPage(name: '/widget/modal', page: () => const ModalScreen(), middlewares: _auth()),
    GetPage(name: '/widget/tabs', page: () => const TabsScreen(), middlewares: _auth()),
    GetPage(name: '/widget/cards', page: () => const CardsScreen(), middlewares: _auth()),
    GetPage(name: '/widget/loader', page: () => const LoadersScreen(), middlewares: _auth()),
    GetPage(name: '/widget/dialog', page: () => const DialogsScreen(), middlewares: _auth()),
    GetPage(name: '/widget/carousel', page: () => const CarouselsScreen(), middlewares: _auth()),
    GetPage(name: '/widget/drag_n_drop', page: () => const DragNDropScreen(), middlewares: _auth()),
    GetPage(name: '/widget/notification', page: () => const NotificationScreen(), middlewares: _auth()),
    GetPage(name: '/form/basic_input', page: () => const BasicInputScreen(), middlewares: _auth()),
    GetPage(name: '/form/custom_option', page: () => const CustomOptionScreen(), middlewares: _auth()),
    GetPage(name: '/form/editor', page: () => const EditorScreen(), middlewares: _auth()),
    GetPage(name: '/form/file_upload', page: () => const FileUploadScreen(), middlewares: _auth()),
    GetPage(name: '/form/slider', page: () => const SliderScreen(), middlewares: _auth()),
    GetPage(name: '/form/validation', page: () => const ValidationScreen(), middlewares: _auth()),
    GetPage(name: '/form/mask', page: () => const MaskScreen(), middlewares: _auth()),
    GetPage(name: '/other/basic_table', page: () => BasicTableScreen(), middlewares: _auth()),

    // ── Extra pages ──────────────────────────────────────────────────────────
    GetPage(name: '/extra/time_line', page: () => TimeLineScreen(), middlewares: _auth()),
    GetPage(name: '/extra/pricing', page: () => PricingScreen(), middlewares: _auth()),
    GetPage(name: '/extra/faqs', page: () => FaqsScreen(), middlewares: _auth()),

    // ── Error pages — no auth required so they are always reachable ──────────
    GetPage(name: '/error/coming_soon', page: () => ComingSoonScreen()),
    GetPage(name: '/error/500', page: () => Error500Screen()),
    GetPage(name: '/error/404', page: () => Error404Screen()),
  ];

  return routes
      .map((e) => GetPage(
            name: e.name,
            page: e.page,
            middlewares: e.middlewares,
            transition: Transition.noTransition,
          ))
      .toList();
}
