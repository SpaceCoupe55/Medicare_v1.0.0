/// Single source of truth for all route name strings.
/// Import this file in both routes.dart and left_bar.dart to prevent drift.
abstract class AppRoutes {
  // Auth
  static const login = '/auth/login';
  static const forgotPassword = '/auth/forgot_password';
  static const resetPassword = '/auth/reset_password';
  static const register = '/auth/register_account';

  // Core
  static const dashboard = '/dashboard';

  // Patients
  static const patientList = '/admin/patient/list';
  static const patientAdd = '/admin/patient/add';
  static const patientDetail = '/admin/patient/detail';
  static const patientEdit = '/admin/patient/edit';

  // Doctors
  static const doctorList = '/admin/doctor/list';
  static const doctorAdd = '/admin/doctor/add';
  static const doctorDetail = '/admin/doctor/detail';
  static const doctorEdit = '/admin/doctor/edit';

  // Appointments
  static const appointmentList = '/admin/appointment/list';
  static const appointmentBook = '/admin/appointment/book';
  static const appointmentEdit = '/admin/appointment/edit';
  static const appointmentSchedule = '/admin/appointment/schedule';

  // Pharmacy
  static const pharmacyList = '/admin/pharmacy/list';
  static const pharmacyAdd = '/admin/pharmacy/add';
  static const pharmacyEdit = '/admin/pharmacy/edit';
  static const pharmacyDetail = '/admin/pharmacy/detail';
  static const pharmacyCart = '/admin/pharmacy/cart';
  static const pharmacyCheckout = '/admin/pharmacy/checkout';
  static const pharmacyReceipt = '/admin/pharmacy/receipt';

  // Doctor portal
  static const doctorPortal = '/doctor/portal';

  // Prescription queue
  static const prescriptionQueue = '/admin/pharmacy/prescriptions';

  // Other
  static const chat = '/admin/chat';
  static const settings = '/admin/setting';
  static const reports = '/admin/reports';

  // Errors
  static const error404 = '/error/404';
  static const error500 = '/error/500';
}
