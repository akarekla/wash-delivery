import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final ValueNotifier<bool> isAdmin = ValueNotifier(false);

  Future<bool> verifyPin(String pin) async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('admin')
        .get();
    final stored =
        doc.exists ? (doc.data()?['pin'] as String? ?? '1234') : '1234';
    if (pin == stored) {
      isAdmin.value = true;
      return true;
    }
    return false;
  }

  Future<void> changePin(String newPin) async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('admin')
        .set({'pin': newPin});
  }

  void logout() => isAdmin.value = false;
}
