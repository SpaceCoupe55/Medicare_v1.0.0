import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/doctor_model.dart';
import 'package:medicare/models/patient_model.dart';
import 'package:medicare/models/sms_log_model.dart';
import 'package:medicare/models/sms_template_model.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/views/my_controller.dart';

enum RecipientMode { individual, bulk }

enum MessageType { standard, appointmentReminder, custom }

enum BulkFilter { all, byDoctor, byDateRange }

class SmsController extends MyController {
  final _db = FirebaseFirestore.instance;

  // ── Auth ────────────────────────────────────────────────────────────────────
  String get _hid => AppAuthController.instance.user?.hospitalId ?? '';
  String get _uid => AppAuthController.instance.user?.uid ?? '';

  // ── Recipient mode ──────────────────────────────────────────────────────────
  RecipientMode recipientMode = RecipientMode.individual;

  // ── Individual mode ─────────────────────────────────────────────────────────
  final TextEditingController patientSearchTE = TextEditingController();
  List<PatientModel> patientResults = [];
  PatientModel? selectedPatient;
  bool searchingPatients = false;
  Timer? _searchDebounce;

  // ── Bulk mode ───────────────────────────────────────────────────────────────
  BulkFilter bulkFilter = BulkFilter.all;
  bool selectAll = false;
  List<PatientModel> bulkPatients = [];
  bool loadingBulk = false;

  // Bulk by doctor
  List<DoctorModel> doctors = [];
  String? selectedDoctorId;

  // Bulk by date range
  DateTime? dateFrom;
  DateTime? dateTo;

  // ── Message composer ────────────────────────────────────────────────────────
  MessageType messageType = MessageType.standard;
  final TextEditingController messageTE = TextEditingController();
  bool sending = false;
  String? sendResult; // success / error text

  // Standard SMS char counter
  int get charCount => messageTE.text.length;
  int get smsPartCount => charCount == 0 ? 1 : ((charCount - 1) ~/ 160) + 1;

  // Custom templates
  List<SmsTemplateModel> templates = [];
  SmsTemplateModel? selectedTemplate;
  bool savingTemplate = false;
  final TextEditingController templateTitleTE = TextEditingController();

  // Appointment reminder fields
  final TextEditingController reminderDateTE = TextEditingController();
  final TextEditingController reminderTimeTE = TextEditingController();
  final TextEditingController reminderDoctorTE = TextEditingController();
  DateTime? reminderDate;

  // ── SMS log ──────────────────────────────────────────────────────────────────
  List<SmsLogModel> smsLog = [];
  bool loadingLog = false;
  Set<String> expandedLogIds = {};

  // ── Auth worker ──────────────────────────────────────────────────────────────
  bool _dataLoaded = false;
  Worker? _authWorker;

  @override
  void onInit() {
    super.onInit();
    messageTE.addListener(() => update());

    final existing = AppAuthController.instance.user;
    if (existing != null && existing.hospitalId.isNotEmpty) {
      _dataLoaded = true;
      _initialLoad();
    }
    _authWorker = ever(AppAuthController.instance.appUser, (UserModel? user) {
      if (user != null && user.hospitalId.isNotEmpty && !_dataLoaded) {
        _dataLoaded = true;
        _initialLoad();
      }
    });
  }

  void _initialLoad() {
    _loadDoctors();
    _loadTemplates();
    _loadLog();
    _loadBulkPatients();
  }

  // ── Recipient: Individual ───────────────────────────────────────────────────

  void setRecipientMode(RecipientMode mode) {
    recipientMode = mode;
    sendResult = null;
    update();
  }

  void onPatientSearchChanged(String q) {
    _searchDebounce?.cancel();
    if (q.trim().isEmpty) {
      patientResults = [];
      update();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () => _searchPatients(q.trim()));
  }

  Future<void> _searchPatients(String q) async {
    if (_hid.isEmpty) return;
    searchingPatients = true;
    update();
    try {
      final lower = q.toLowerCase();
      final snap = await _db
          .collection('patients')
          .where('hospitalId', isEqualTo: _hid)
          .limit(30)
          .get();
      patientResults = snap.docs
          .map(PatientModel.fromFirestore)
          .where((p) =>
              p.name.toLowerCase().contains(lower) ||
              p.mobileNumber.contains(q))
          .toList();
    } catch (_) {
      patientResults = [];
    } finally {
      searchingPatients = false;
      update();
    }
  }

  void selectPatient(PatientModel p) {
    selectedPatient = p;
    patientResults = [];
    patientSearchTE.text = p.name;
    sendResult = null;
    _prefillReminderDoctor(p);
    update();
  }

  void clearPatient() {
    selectedPatient = null;
    patientSearchTE.clear();
    patientResults = [];
    update();
  }

  void _prefillReminderDoctor(PatientModel p) {
    if (p.assignedDoctorId.isEmpty) return;
    final doc = doctors.firstWhereOrNull((d) => d.id == p.assignedDoctorId);
    if (doc != null) reminderDoctorTE.text = doc.doctorName;
  }

  // ── Recipient: Bulk ─────────────────────────────────────────────────────────

  void setBulkFilter(BulkFilter f) {
    bulkFilter = f;
    selectedDoctorId = null;
    dateFrom = null;
    dateTo = null;
    sendResult = null;
    _loadBulkPatients();
  }

  void setSelectedDoctor(String? id) {
    selectedDoctorId = id;
    _loadBulkPatients();
  }

  Future<void> setDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: dateFrom != null && dateTo != null
          ? DateTimeRange(start: dateFrom!, end: dateTo!)
          : null,
    );
    if (range != null) {
      dateFrom = range.start;
      dateTo = range.end;
      _loadBulkPatients();
    }
  }

  Future<void> _loadBulkPatients() async {
    if (_hid.isEmpty) return;
    loadingBulk = true;
    update();
    try {
      Query<Map<String, dynamic>> q =
          _db.collection('patients').where('hospitalId', isEqualTo: _hid);

      if (bulkFilter == BulkFilter.byDoctor && selectedDoctorId != null) {
        q = q.where('assignedDoctorId', isEqualTo: selectedDoctorId);
      } else if (bulkFilter == BulkFilter.byDateRange &&
          dateFrom != null &&
          dateTo != null) {
        q = q
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dateFrom!))
            .where('createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(
                    dateTo!.add(const Duration(days: 1))));
      }

      final snap = await q.limit(500).get();
      bulkPatients = snap.docs.map(PatientModel.fromFirestore).toList();
      selectAll = true;
    } catch (_) {
      bulkPatients = [];
    } finally {
      loadingBulk = false;
      update();
    }
  }

  void toggleSelectAll(bool? v) {
    selectAll = v ?? false;
    update();
  }

  // ── Doctors list ────────────────────────────────────────────────────────────

  Future<void> _loadDoctors() async {
    if (_hid.isEmpty) return;
    try {
      final snap = await _db
          .collection('doctors')
          .where('hospitalId', isEqualTo: _hid)
          .limit(100)
          .get();
      doctors = snap.docs.map(DoctorModel.fromFirestore).toList()
        ..sort((a, b) => a.doctorName.compareTo(b.doctorName));
      update();
    } catch (_) {}
  }

  // ── Message type ────────────────────────────────────────────────────────────

  void setMessageType(MessageType t) {
    messageType = t;
    sendResult = null;
    if (t == MessageType.appointmentReminder) {
      _buildReminderTemplate();
    } else if (t == MessageType.custom && selectedTemplate != null) {
      messageTE.text = selectedTemplate!.body;
    } else if (t == MessageType.standard) {
      messageTE.clear();
    }
    update();
  }

  void _buildReminderTemplate() {
    final patientName = recipientMode == RecipientMode.individual
        ? (selectedPatient?.name ?? '[Patient Name]')
        : '[Patient Name]';
    final date = reminderDate != null
        ? '${reminderDate!.day}/${reminderDate!.month}/${reminderDate!.year}'
        : '[Date]';
    final time = reminderTimeTE.text.isNotEmpty ? reminderTimeTE.text : '[Time]';
    final doctor = reminderDoctorTE.text.isNotEmpty
        ? reminderDoctorTE.text
        : '[Doctor Name]';
    final hospital =
        AppAuthController.instance.user?.name ?? '[Hospital Name]';

    messageTE.text =
        'Dear $patientName, this is a reminder for your appointment on $date '
        'at $time with Dr. $doctor at $hospital. Please arrive 15 minutes '
        'early. Reply STOP to unsubscribe.';
    update();
  }

  Future<void> pickReminderDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      reminderDate = picked;
      reminderDateTE.text =
          '${picked.day}/${picked.month}/${picked.year}';
      _buildReminderTemplate();
    }
  }

  Future<void> pickReminderTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      // ignore: use_build_context_synchronously
      reminderTimeTE.text = picked.format(context);
      _buildReminderTemplate();
    }
  }

  void onReminderDoctorChanged(String v) {
    _buildReminderTemplate();
  }

  // ── Templates ────────────────────────────────────────────────────────────────

  Future<void> _loadTemplates() async {
    if (_hid.isEmpty) return;
    try {
      final snap = await _db
          .collection('smsTemplates')
          .where('hospitalId', isEqualTo: _hid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      templates = snap.docs.map(SmsTemplateModel.fromFirestore).toList();
      update();
    } catch (_) {}
  }

  void selectTemplate(SmsTemplateModel t) {
    selectedTemplate = t;
    messageTE.text = t.body;
    update();
  }

  Future<void> saveAsTemplate() async {
    final title = templateTitleTE.text.trim();
    final body = messageTE.text.trim();
    if (title.isEmpty || body.isEmpty || _hid.isEmpty) return;
    savingTemplate = true;
    update();
    try {
      await _db.collection('smsTemplates').add({
        'title': title,
        'body': body,
        'hospitalId': _hid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      templateTitleTE.clear();
      await _loadTemplates();
      Get.snackbar('Saved', 'Template "$title" saved.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50),
          colorText: const Color(0xFFFFFFFF));
    } catch (_) {
      Get.snackbar('Error', 'Could not save template.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFF44336),
          colorText: const Color(0xFFFFFFFF));
    } finally {
      savingTemplate = false;
      update();
    }
  }

  // ── mNotify API ───────────────────────────────────────────────────────────────

  static const _mnotifyApiKey = 'WUKb6M3un9vveHesNTHVbDyjQ';
  static const _mnotifySenderId = 'SkillUp';

  /// Formats a phone number to Ghana local format (0XXXXXXXXX).
  String _formatGhanaPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('233') && digits.length == 12) {
      return '0${digits.substring(3)}';
    }
    if (!digits.startsWith('0') && digits.length == 9) {
      return '0$digits';
    }
    return digits;
  }

  /// Sends an SMS via mNotify and returns true on success.
  Future<bool> _callMnotify(List<String> phones, String message) async {
    final formatted = phones
        .map(_formatGhanaPhone)
        .where((p) => p.length == 10 && p.startsWith('0'))
        .toList();
    if (formatted.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('https://api.mnotify.com/api/sms/quick?key=$_mnotifyApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipient': formatted,
          'sender': _mnotifySenderId,
          'message': message,
          'is_schedule': 'false',
          'schedule_date': '',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Send ─────────────────────────────────────────────────────────────────────

  Future<void> send() async {
    sendResult = null;

    // Build recipient list
    List<SmsRecipient> recipients;
    if (recipientMode == RecipientMode.individual) {
      if (selectedPatient == null) {
        sendResult = 'error:Please select a patient first.';
        update();
        return;
      }
      recipients = [
        SmsRecipient(
          patientId: selectedPatient!.id,
          name: selectedPatient!.name,
          phone: selectedPatient!.mobileNumber,
        )
      ];
    } else {
      final list = selectAll ? bulkPatients : [];
      if (list.isEmpty) {
        sendResult = 'error:No patients selected.';
        update();
        return;
      }
      recipients = list
          .map((p) => SmsRecipient(
                patientId: p.id,
                name: p.name,
                phone: p.mobileNumber,
              ))
          .toList();
    }

    final msg = messageTE.text.trim();
    if (msg.isEmpty) {
      sendResult = 'error:Message cannot be empty.';
      update();
      return;
    }

    sending = true;
    update();

    // Call mNotify gateway
    final phones = recipients.map((r) => r.phone).toList();
    final apiSuccess = await _callMnotify(phones, msg);
    final status = apiSuccess ? 'sent' : 'failed';

    try {
      await _db.collection('smsLog').add({
        'recipients': recipients.map((r) => r.toMap()).toList(),
        'message': msg,
        'sentBy': _uid,
        'sentAt': FieldValue.serverTimestamp(),
        'status': status,
        'recipientCount': recipients.length,
        'hospitalId': _hid,
      });

      if (apiSuccess) {
        sendResult = 'success:Message sent to ${recipients.length} recipient${recipients.length == 1 ? '' : 's'}.';
        messageTE.clear();
      } else {
        sendResult = 'error:Gateway error — message not delivered. Check your mNotify account or sender ID.';
      }
      await _loadLog();
    } catch (e) {
      sendResult = 'error:Failed to save log: $e';
    } finally {
      sending = false;
      update();
    }
  }

  // ── SMS Log ──────────────────────────────────────────────────────────────────

  Future<void> _loadLog() async {
    if (_hid.isEmpty) return;
    loadingLog = true;
    update();
    try {
      final snap = await _db
          .collection('smsLog')
          .where('hospitalId', isEqualTo: _hid)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .get();
      smsLog = snap.docs.map(SmsLogModel.fromFirestore).toList();
    } catch (_) {
      smsLog = [];
    } finally {
      loadingLog = false;
      update();
    }
  }

  void toggleLogRow(String id) {
    if (expandedLogIds.contains(id)) {
      expandedLogIds.remove(id);
    } else {
      expandedLogIds.add(id);
    }
    update();
  }

  // ── Cleanup ──────────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _authWorker?.dispose();
    patientSearchTE.dispose();
    messageTE.dispose();
    templateTitleTE.dispose();
    reminderDateTE.dispose();
    reminderTimeTE.dispose();
    reminderDoctorTE.dispose();
    super.onClose();
  }
}
