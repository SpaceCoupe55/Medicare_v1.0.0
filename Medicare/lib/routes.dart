import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/route_names.dart';

// ── Screens ──────────────────────────────────────────────────────────────────
import 'package:medicare/views/auth/forgot_password_screen.dart';
import 'package:medicare/views/auth/login_screen.dart';
import 'package:medicare/views/auth/register_account_screen.dart';
import 'package:medicare/views/auth/reset_password_screen.dart';
import 'package:medicare/views/ui/appointment_book_screen.dart';
import 'package:medicare/views/ui/appointment_edit_screen.dart';
import 'package:medicare/views/ui/appointment_list_screen.dart';
import 'package:medicare/views/ui/appointment_scheduling_screen.dart';
import 'package:medicare/views/ui/chat_screen.dart';
import 'package:medicare/views/ui/dashboard_screen.dart';
import 'package:medicare/views/ui/doctor_add_screen.dart';
import 'package:medicare/views/ui/doctor_detail_screen.dart';
import 'package:medicare/views/ui/doctor_edit_screen.dart';
import 'package:medicare/views/ui/doctor_list_screen.dart';
import 'package:medicare/views/ui/error_pages/error_404_screen.dart';
import 'package:medicare/views/ui/error_pages/error_500_screen.dart';
import 'package:medicare/views/ui/patient_add_screen.dart';
import 'package:medicare/views/ui/patient_detail_screen.dart';
import 'package:medicare/views/ui/patient_edit_screen.dart';
import 'package:medicare/views/ui/patient_list_screen.dart';
import 'package:medicare/views/ui/pharmacy_add_screen.dart';
import 'package:medicare/views/ui/pharmacy_cart_screen.dart';
import 'package:medicare/views/ui/pharmacy_checkout_screen.dart';
import 'package:medicare/views/ui/pharmacy_detail_screen.dart';
import 'package:medicare/views/ui/pharmacy_edit_screen.dart';
import 'package:medicare/views/ui/pharmacy_list_screen.dart';
import 'package:medicare/views/ui/pharmacy_receipt_screen.dart';
import 'package:medicare/views/ui/billing_list_screen.dart';
import 'package:medicare/views/ui/roster_screen.dart';
import 'package:medicare/views/ui/doctor_portal_screen.dart';
import 'package:medicare/views/ui/invoice_create_screen.dart';
import 'package:medicare/views/ui/invoice_detail_screen.dart';
import 'package:medicare/views/ui/prescription_queue_screen.dart';
import 'package:medicare/views/ui/reports_screen.dart';
import 'package:medicare/views/ui/setting_screen.dart';

// ── Middleware ────────────────────────────────────────────────────────────────

/// Redirects unauthenticated users to the login page.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (FirebaseAuth.instance.currentUser != null) return null;
    final next = Uri.encodeComponent(route ?? '/');
    return RouteSettings(name: '${AppRoutes.login}?next=$next');
  }
}

/// Redirects users whose role is not in [allowedRoles] to the dashboard.
/// Place after [AuthMiddleware].
class RoleMiddleware extends GetMiddleware {
  final List<UserRole> allowedRoles;
  RoleMiddleware(this.allowedRoles);

  @override
  RouteSettings? redirect(String? route) {
    final user = AppAuthController.instance.user;
    if (user == null) return null; // Auth middleware already handles unauthenticated
    if (!allowedRoles.contains(user.role)) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }
    return null;
  }
}

// Convenience middleware lists.
List<GetMiddleware> _auth() => [AuthMiddleware()];
List<GetMiddleware> _adminOnly() =>
    [AuthMiddleware(), RoleMiddleware([UserRole.admin])];
List<GetMiddleware> _clinicalStaff() => [
      AuthMiddleware(),
      RoleMiddleware([UserRole.admin, UserRole.doctor, UserRole.nurse]),
    ];
List<GetMiddleware> _pharmacyStaff() => [
      AuthMiddleware(),
      RoleMiddleware([UserRole.admin, UserRole.receptionist]),
    ];
List<GetMiddleware> _doctorOnly() =>
    [AuthMiddleware(), RoleMiddleware([UserRole.doctor])];

// ── Route table ───────────────────────────────────────────────────────────────

List<GetPage> getPageRoute() {
  final routes = [
    // ── Root ─────────────────────────────────────────────────────────────────
    GetPage(
      name: '/',
      page: () => const DashboardScreen(),
      middlewares: _auth(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      middlewares: _auth(),
    ),

    // ── Auth (no guard) ───────────────────────────────────────────────────────
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterAccountScreen()),
    GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: AppRoutes.resetPassword, page: () => const ResetPasswordScreen()),

    // ── Patients — clinical staff ─────────────────────────────────────────────
    GetPage(
      name: AppRoutes.patientList,
      page: () => const PatientListScreen(),
      middlewares: _clinicalStaff(),
    ),
    GetPage(
      name: AppRoutes.patientAdd,
      page: () => const PatientAddScreen(),
      middlewares: _clinicalStaff(),
    ),
    GetPage(
      name: AppRoutes.patientDetail,
      page: () => const PatientDetailScreen(),
      middlewares: _clinicalStaff(),
    ),
    GetPage(
      name: AppRoutes.patientEdit,
      page: () => const PatientEditScreen(),
      middlewares: _clinicalStaff(),
    ),

    // ── Doctors — list/detail: clinical staff; add/edit: admin only ───────────
    GetPage(
      name: AppRoutes.doctorList,
      page: () => const DoctorListScreen(),
      middlewares: _clinicalStaff(),
    ),
    GetPage(
      name: AppRoutes.doctorAdd,
      page: () => const DoctorAddScreen(),
      middlewares: _adminOnly(),
    ),
    GetPage(
      name: AppRoutes.doctorDetail,
      page: () => const DoctorDetailScreen(),
      middlewares: _clinicalStaff(),
    ),
    GetPage(
      name: AppRoutes.doctorEdit,
      page: () => const DoctorEditScreen(),
      middlewares: _adminOnly(),
    ),

    // ── Appointments — clinical staff ─────────────────────────────────────────
    GetPage(
      name: AppRoutes.appointmentList,
      page: () => const AppointmentListScreen(),
      middlewares: _clinicalStaff(),
    ),
    GetPage(
      name: AppRoutes.appointmentBook,
      page: () => const AppointmentBookScreen(),
      middlewares: _clinicalStaff(),
    ),
    GetPage(
      name: AppRoutes.appointmentEdit,
      page: () => const AppointmentEditScreen(),
      middlewares: _clinicalStaff(),
    ),
    GetPage(
      name: AppRoutes.appointmentSchedule,
      page: () => const AppointmentSchedulingScreen(),
      middlewares: _clinicalStaff(),
    ),

    // ── Pharmacy — admin or receptionist ──────────────────────────────────────
    GetPage(
      name: AppRoutes.pharmacyList,
      page: () => const PharmacyListScreen(),
      middlewares: _pharmacyStaff(),
    ),
    GetPage(
      name: AppRoutes.pharmacyAdd,
      page: () => const PharmacyAddScreen(),
      middlewares: _pharmacyStaff(),
    ),
    GetPage(
      name: AppRoutes.pharmacyDetail,
      page: () => const PharmacyDetailScreen(),
      middlewares: _pharmacyStaff(),
    ),
    GetPage(
      name: AppRoutes.pharmacyCart,
      page: () => const PharmacyCartScreen(),
      middlewares: _pharmacyStaff(),
    ),
    GetPage(
      name: AppRoutes.pharmacyCheckout,
      page: () => const PharmacyCheckoutScreen(),
      middlewares: _pharmacyStaff(),
    ),
    GetPage(
      name: AppRoutes.pharmacyEdit,
      page: () => const PharmacyEditScreen(),
      middlewares: _adminOnly(),
    ),
    GetPage(
      name: AppRoutes.pharmacyReceipt,
      page: () => const PharmacyReceiptScreen(),
      middlewares: _pharmacyStaff(),
    ),

    // ── Prescription queue — pharmacy staff ───────────────────────────────────
    GetPage(
      name: AppRoutes.prescriptionQueue,
      page: () => const PrescriptionQueueScreen(),
      middlewares: _pharmacyStaff(),
    ),

    // ── Billing — admin or receptionist ──────────────────────────────────────
    GetPage(
      name: AppRoutes.billingList,
      page: () => const BillingListScreen(),
      middlewares: _pharmacyStaff(),
    ),
    GetPage(
      name: AppRoutes.invoiceCreate,
      page: () => const InvoiceCreateScreen(),
      middlewares: _pharmacyStaff(),
    ),
    GetPage(
      name: AppRoutes.invoiceDetail,
      page: () => const InvoiceDetailScreen(),
      middlewares: _pharmacyStaff(),
    ),

    // ── Staff Roster — admin only ─────────────────────────────────────────────
    GetPage(
      name: AppRoutes.roster,
      page: () => const RosterScreen(),
      middlewares: _adminOnly(),
    ),

    // ── Doctor portal — doctor role only ──────────────────────────────────────
    GetPage(
      name: AppRoutes.doctorPortal,
      page: () => const DoctorPortalScreen(),
      middlewares: _doctorOnly(),
    ),

    // ── Chat — all authenticated users ────────────────────────────────────────
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreen(),
      middlewares: _auth(),
    ),

    // ── Admin only ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingScreen(),
      middlewares: _adminOnly(),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsScreen(),
      middlewares: _adminOnly(),
    ),

    // ── Error pages (no auth required) ────────────────────────────────────────
    GetPage(name: AppRoutes.error500, page: () => const Error500Screen()),
    GetPage(name: AppRoutes.error404, page: () => const Error404Screen()),
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
