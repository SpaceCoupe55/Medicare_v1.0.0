import 'package:medicare/views/my_controller.dart';

class FaqsController extends MyController {
  final List<bool> dataExpansionPanel = [true, false, false, false, false, false];

  /// Answers corresponding to the questions rendered in faqs_screen.dart.
  final List<String> answers = [
    'To book an appointment, navigate to Appointments → Book Appointment from the sidebar. '
        'Select the patient, choose an available doctor, pick a date and time slot, then tap Save. '
        'The assigned doctor will receive an in-app and push notification automatically.',
    'Doctors and nurses can view a full patient profile — including medical history, blood group, '
        'prescriptions, and uploaded reports — by opening Patients → Patient List and tapping the '
        'eye icon on any row. Uploading new reports is available on the Patient Edit screen.',
    'The system uses Firebase Cloud Messaging (FCM). When an appointment is created, the assigned '
        'doctor is notified instantly. When a status changes to Cancelled or Completed, the patient '
        'is notified. Daily 8 AM reminders are also sent automatically for all appointments scheduled '
        'that day.',
    'Pharmacy records (product list, cart, and checkout) are accessible to Admin and Receptionist '
        'roles only. Doctors and nurses can view patient records and appointments but cannot access '
        'pharmacy inventory.',
    'Only Admin users can add new doctors. Go to Doctors → Add Doctor from the sidebar, fill in the '
        'doctor\'s details, and tap Save. The doctor\'s account must then be created separately via '
        'Firebase Authentication using the Create Hospital Admin function or directly in the '
        'Firebase Console.',
    'On the Login screen, tap Forgot Password and enter your registered email address. A password-reset '
        'link will be sent to that address. Once reset, you can log in with your new password. '
        'Admins can also update passwords directly from the Settings page.',
  ];
}
