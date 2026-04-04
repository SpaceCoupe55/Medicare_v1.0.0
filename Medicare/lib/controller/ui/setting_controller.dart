import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/views/my_controller.dart';

class SettingController extends MyController {
  // ── Personal Info ─────────────────────────────────────────────────────────
  late TextEditingController firstNameTE;
  late TextEditingController lastNameTE;
  late TextEditingController emailTE;
  late TextEditingController phoneTE;
  bool savingProfile = false;

  // ── Avatar ────────────────────────────────────────────────────────────────
  bool savingAvatar = false;
  double? uploadProgress; // null = not uploading, 0.0–1.0 = in progress

  // ── Password ─────────────────────────────────────────────────────────────
  late TextEditingController currentPasswordTE;
  late TextEditingController newPasswordTE;
  late TextEditingController confirmPasswordTE;
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;
  bool savingPassword = false;

  // ── Hospital settings (admin only) ────────────────────────────────────────
  late TextEditingController hospitalNameTE;
  late TextEditingController hospitalContactTE;
  bool isAdmin = false;
  bool savingHospital = false;

  @override
  void onInit() {
    firstNameTE      = TextEditingController();
    lastNameTE       = TextEditingController();
    emailTE          = TextEditingController();
    phoneTE          = TextEditingController();
    currentPasswordTE = TextEditingController();
    newPasswordTE    = TextEditingController();
    confirmPasswordTE = TextEditingController();
    hospitalNameTE   = TextEditingController();
    hospitalContactTE = TextEditingController();
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AppAuthController.instance.user;
    if (user == null) return;

    final parts = user.name.trim().split(' ');
    firstNameTE.text = parts.first;
    lastNameTE.text  = parts.length > 1 ? parts.skip(1).join(' ') : '';
    emailTE.text     = user.email;
    phoneTE.text     = user.phone;
    isAdmin          = user.role == UserRole.admin;

    if (isAdmin) await _loadHospital(user.hospitalId);
    update();
  }

  Future<void> _loadHospital(String hospitalId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hospitals')
          .doc(hospitalId)
          .get();
      if (doc.exists) {
        hospitalNameTE.text    = doc.data()?['name']    as String? ?? '';
        hospitalContactTE.text = doc.data()?['contact'] as String? ?? '';
      }
    } catch (_) {}
  }

  // ── Profile save ──────────────────────────────────────────────────────────

  Future<void> saveProfile() async {
    final uid = AppAuthController.instance.user?.uid;
    if (uid == null) return;

    final fullName = '${firstNameTE.text.trim()} ${lastNameTE.text.trim()}'.trim();
    if (fullName.isEmpty) {
      Get.snackbar('Validation', 'Name cannot be empty.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
      return;
    }

    savingProfile = true;
    update();
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name':  fullName,
        'phone': phoneTE.text.trim(),
      });
      // Update Firebase Auth display name too
      await FirebaseAuth.instance.currentUser?.updateDisplayName(fullName);
      // Stream in AppAuthController will auto-update appUser — no manual fetchUser needed
      Get.snackbar('Success', 'Profile updated.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (_) {
      Get.snackbar('Error', 'Failed to update profile.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      savingProfile = false;
      update();
    }
  }

  // ── Avatar upload ─────────────────────────────────────────────────────────

  Future<void> pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true, // required on web — gives bytes instead of path
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final uid = AppAuthController.instance.user?.uid;
    if (uid == null) return;

    savingAvatar     = true;
    uploadProgress   = 0.0;
    update();

    try {
      final ref = FirebaseStorage.instance
          .ref('users/$uid/avatar/profile.jpg');
      final task = ref.putData(
        file.bytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          uploadProgress = snap.bytesTransferred / snap.totalBytes;
          update();
        }
      });

      await task;
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'avatarUrl': url});
      // AppAuthController's real-time stream will propagate the new avatarUrl
      // to the navbar automatically.

      Get.snackbar('Success', 'Profile photo updated.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (_) {
      Get.snackbar('Error', 'Failed to upload photo.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      savingAvatar   = false;
      uploadProgress = null;
      update();
    }
  }

  // ── Password visibility toggles ───────────────────────────────────────────

  void toggleCurrentPassword() { showCurrentPassword = !showCurrentPassword; update(); }
  void toggleNewPassword()     { showNewPassword     = !showNewPassword;     update(); }
  void toggleConfirmPassword() { showConfirmPassword = !showConfirmPassword; update(); }

  // ── Password change ───────────────────────────────────────────────────────

  Future<void> changePassword() async {
    if (currentPasswordTE.text.isEmpty ||
        newPasswordTE.text.isEmpty ||
        confirmPasswordTE.text.isEmpty) {
      Get.snackbar('Validation', 'Please fill in all password fields.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
      return;
    }
    if (newPasswordTE.text.length < 8) {
      Get.snackbar('Validation', 'New password must be at least 8 characters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
      return;
    }
    if (newPasswordTE.text != confirmPasswordTE.text) {
      Get.snackbar('Validation', 'New passwords do not match.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser?.email == null) return;

    savingPassword = true;
    update();
    try {
      final cred = EmailAuthProvider.credential(
        email: firebaseUser!.email!,
        password: currentPasswordTE.text,
      );
      await firebaseUser.reauthenticateWithCredential(cred);
      await firebaseUser.updatePassword(newPasswordTE.text);
      currentPasswordTE.clear();
      newPasswordTE.clear();
      confirmPasswordTE.clear();
      Get.snackbar('Success', 'Password changed successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } on FirebaseAuthException catch (e) {
      final msg = (e.code == 'wrong-password' || e.code == 'invalid-credential')
          ? 'Current password is incorrect.'
          : (e.message ?? 'Failed to update password.');
      Get.snackbar('Error', msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } catch (_) {
      Get.snackbar('Error', 'Failed to update password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      savingPassword = false;
      update();
    }
  }

  // ── Hospital settings (admin) ─────────────────────────────────────────────

  Future<void> saveHospital() async {
    final hospitalId = AppAuthController.instance.user?.hospitalId;
    if (hospitalId == null || hospitalId.isEmpty) return;

    savingHospital = true;
    update();
    try {
      await FirebaseFirestore.instance
          .collection('hospitals')
          .doc(hospitalId)
          .set({
        'name':    hospitalNameTE.text.trim(),
        'contact': hospitalContactTE.text.trim(),
      }, SetOptions(merge: true));
      Get.snackbar('Success', 'Hospital settings updated.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (_) {
      Get.snackbar('Error', 'Failed to save hospital settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      savingHospital = false;
      update();
    }
  }

  @override
  void onClose() {
    firstNameTE.dispose();
    lastNameTE.dispose();
    emailTE.dispose();
    phoneTE.dispose();
    currentPasswordTE.dispose();
    newPasswordTE.dispose();
    confirmPasswordTE.dispose();
    hospitalNameTE.dispose();
    hospitalContactTE.dispose();
    super.onClose();
  }
}
