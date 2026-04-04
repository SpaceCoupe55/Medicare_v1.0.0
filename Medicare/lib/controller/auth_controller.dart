import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/services/auth_service.dart';
import 'package:medicare/services/fcm_service.dart';

class AppAuthController extends GetxController {
  static AppAuthController get instance => Get.find<AppAuthController>();

  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FcmService _fcmService = FcmService();

  final Rxn<UserModel> appUser = Rxn<UserModel>();

  StreamSubscription? _userDocSub;

  bool get isLoggedIn => appUser.value != null;
  UserModel? get user => appUser.value;
  UserRole? get role => appUser.value?.role;

  // ── Reactive display helpers ──────────────────────────────────────────────

  /// Display name: full name if set, else the part before @ in email.
  String get userName {
    final n = appUser.value?.name ?? '';
    if (n.isNotEmpty) return n;
    final email = appUser.value?.email ?? '';
    return email.contains('@') ? email.split('@').first : email;
  }

  String? get userAvatarUrl => appUser.value?.avatarUrl;
  String get userEmail => appUser.value?.email ?? '';
  UserRole? get userRole => appUser.value?.role;

  @override
  void onInit() {
    super.onInit();
    _authService.userStream.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _userDocSub?.cancel();
    _userDocSub = null;

    if (firebaseUser == null) {
      appUser.value = null;
      return;
    }

    _subscribeToUserDoc(firebaseUser.uid);
    _fcmService.init(firebaseUser.uid);
  }

  /// Opens a real-time stream on users/{uid}.
  /// Updates appUser reactively whenever the Firestore document changes
  /// (e.g. after a profile/avatar update in settings).
  void _subscribeToUserDoc(String uid) {
    _userDocSub = _db.collection('users').doc(uid).snapshots().listen(
      (doc) {
        if (doc.exists) {
          appUser.value = UserModel.fromFirestore(doc);
        } else {
          // Profile document deleted — sign out
          _authService.signOut();
        }
      },
      onError: (_) {
        // Keep existing value on transient errors
      },
    );
  }

  /// Force a one-shot refresh (kept for backward compatibility).
  Future<void> fetchUser(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) appUser.value = UserModel.fromFirestore(doc);
    } catch (_) {}
  }

  Future<void> signOut() async {
    final uid = appUser.value?.uid;
    if (uid != null) await _fcmService.clearToken(uid);
    _userDocSub?.cancel();
    await _authService.signOut();
    appUser.value = null;
    Get.offAllNamed('/auth/login');
  }

  @override
  void onClose() {
    _userDocSub?.cancel();
    super.onClose();
  }
}
