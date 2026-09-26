import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown when deleting the account can't go ahead (wrong password, offline…).
class AccountDeletionException implements Exception {
  final String message;
  const AccountDeletionException(this.message);

  @override
  String toString() => message;
}

/// Permanently deletes the signed-in user's account and everything stored
/// for it, as Google Play requires for apps that let people sign up.
class AccountService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AccountService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Subcollections under users/{uid}. Keep in sync with FirestoreService
  /// and CreditService when adding new ones.
  static const _subcollections = ['days', 'wallet', 'creditLedger'];

  /// Email accounts must confirm their password; guest accounts don't have one.
  bool get needsPassword =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;

  String? get email => _auth.currentUser?.email;

  /// Deletes the user's data, then the sign-in account itself. The password is
  /// checked first, so a typo can't leave the data deleted and the account
  /// still there.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AccountDeletionException('You are not signed in.');
    }

    try {
      if (needsPassword) {
        if (password == null || password.isEmpty) {
          throw const AccountDeletionException('Enter your password to confirm.');
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      }

      await _deleteUserData(user.uid).timeout(const Duration(seconds: 30));
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await user.delete();
      log('AccountService: account ${user.uid} deleted');
    } on AccountDeletionException {
      rethrow;
    } on TimeoutException {
      throw const AccountDeletionException(
          "Couldn't reach the server. Check your connection and try again.");
    } on FirebaseAuthException catch (e) {
      throw AccountDeletionException(switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'That password is incorrect.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => "Couldn't reach the server. Check your connection and try again.",
        'requires-recent-login' => 'For your security, sign in again and then delete your account.',
        _ => 'Account deletion failed (${e.code}). Please try again.',
      });
    }
  }

  Future<void> _deleteUserData(String uid) async {
    final userDoc = _firestore.collection('users').doc(uid);
    for (final name in _subcollections) {
      // Batches are limited to 500 writes; delete page by page.
      while (true) {
        final page = await userDoc.collection(name).limit(400).get();
        if (page.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final doc in page.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await userDoc.delete();
  }
}
