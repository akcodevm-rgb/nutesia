import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/credit_constants.dart';
import '../models/credit_state.dart';
import '../utils/date_utils.dart';

class CreditException implements Exception {
  final String message;
  final int requiredCredits;
  final int currentCredits;

  const CreditException({
    required this.message,
    required this.requiredCredits,
    required this.currentCredits,
  });

  @override
  String toString() => message;
}

class RewardLimitException implements Exception {
  final String message;

  const RewardLimitException(this.message);

  @override
  String toString() => message;
}

class CreditService {
  final FirebaseFirestore _firestore;

  CreditService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _walletRef(String deviceId) =>
      _firestore
          .collection('users')
          .doc(deviceId)
          .collection('wallet')
          .doc('main');

  CollectionReference<Map<String, dynamic>> _ledgerRef(String deviceId) =>
      _firestore.collection('users').doc(deviceId).collection('creditLedger');

  Future<void> _ensureWalletExists(String deviceId) async {
    final walletRef = _walletRef(deviceId);
    final doc = await walletRef.get();
    if (!doc.exists) {
      try {
        await walletRef.set({
          ...const CreditState.empty().toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Ignore write conflicts if created concurrently by another device/instance
      }
    }
  }

  Stream<CreditState> watchWallet(String deviceId) {
    return _walletRef(deviceId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return const CreditState.empty();
      return CreditState.fromJson(data);
    });
  }

  Future<CreditState> loadWallet(String deviceId) async {
    final doc = await _walletRef(deviceId).get();
    final data = doc.data();
    if (data == null) return const CreditState.empty();
    return CreditState.fromJson(data);
  }

  Future<CreditState> grantDailyCreditsIfNeeded(String deviceId) async {
    // Admin bypass: akhil@gmail.com gets unlimited credits
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email?.toLowerCase() == 'akhil@gmail.com') {
      return const CreditState(
        creditBalance: 9999,
        lastDailyGrantDate: 'admin',
        rewardedAdsWatchedToday: 0,
        lastAdRewardDate: '',
        totalEarnedCredits: 9999,
        totalSpentCredits: 0,
      );
    }

    await _ensureWalletExists(deviceId);
    final today = AppDateUtils.todayKey();
    return _firestore.runTransaction((tx) async {
      final walletRef = _walletRef(deviceId);
      final ledgerRef = _ledgerRef(deviceId).doc();
      final snapshot = await tx.get(walletRef);
      final current = snapshot.data() != null
          ? CreditState.fromJson(snapshot.data()!)
          : const CreditState.empty();

      final adsWatchedToday = current.lastAdRewardDate == today
          ? current.rewardedAdsWatchedToday
          : 0;

      if (current.lastDailyGrantDate == today) {
        final normalized = current.copyWith(
          rewardedAdsWatchedToday: adsWatchedToday,
          lastAdRewardDate: current.lastAdRewardDate.isEmpty
              ? today
              : current.lastAdRewardDate,
        );
        if (!snapshot.exists ||
            normalized.toJson().toString() != current.toJson().toString()) {
          tx.set(
            walletRef,
            {
              ...normalized.toJson(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        return normalized;
      }

      final creditBalance =
          (current.creditBalance + CreditConstants.dailyFreeCredits)
              .clamp(0, CreditConstants.maxCreditBalance)
              .toInt();
      final earned = creditBalance - current.creditBalance;
      final updated = current.copyWith(
        creditBalance: creditBalance,
        lastDailyGrantDate: today,
        rewardedAdsWatchedToday: 0,
        lastAdRewardDate: today,
        totalEarnedCredits: current.totalEarnedCredits + earned,
      );

      tx.set(
        walletRef,
        {
          ...updated.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (earned > 0) {
        tx.set(ledgerRef, {
          'type': 'daily_grant',
          'amount': earned,
          'balanceAfter': updated.creditBalance,
          'reason': 'daily_free_credits',
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {'date': today},
        });
      }

      return updated;
    });
  }

  Future<CreditState> spendCredits({
    required String deviceId,
    required int amount,
    required String reason,
  }) async {
    // Admin bypass: akhil@gmail.com gets unlimited credits
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email?.toLowerCase() == 'akhil@gmail.com') {
      return const CreditState(
        creditBalance: 9999,
        lastDailyGrantDate: 'admin',
        rewardedAdsWatchedToday: 0,
        lastAdRewardDate: '',
        totalEarnedCredits: 9999,
        totalSpentCredits: 0,
      );
    }

    await _ensureWalletExists(deviceId);
    return _firestore.runTransaction((tx) async {
      final walletRef = _walletRef(deviceId);
      final ledgerRef = _ledgerRef(deviceId).doc();
      final snapshot = await tx.get(walletRef);
      final current = snapshot.data() != null
          ? CreditState.fromJson(snapshot.data()!)
          : const CreditState.empty();

      if (current.creditBalance < amount) {
        throw CreditException(
          message: 'Not enough credits',
          requiredCredits: amount,
          currentCredits: current.creditBalance,
        );
      }

      final updated = current.copyWith(
        creditBalance: current.creditBalance - amount,
        totalSpentCredits: current.totalSpentCredits + amount,
      );

      tx.set(
        walletRef,
        {
          ...updated.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(ledgerRef, {
        'type': '${reason}_spend',
        'amount': -amount,
        'balanceAfter': updated.creditBalance,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return updated;
    });
  }

  Future<CreditState> refundCredits({
    required String deviceId,
    required int amount,
    required String reason,
  }) async {
    await _ensureWalletExists(deviceId);
    return _firestore.runTransaction((tx) async {
      final walletRef = _walletRef(deviceId);
      final ledgerRef = _ledgerRef(deviceId).doc();
      final snapshot = await tx.get(walletRef);
      final current = snapshot.data() != null
          ? CreditState.fromJson(snapshot.data()!)
          : const CreditState.empty();

      final updated = current.copyWith(
        creditBalance: (current.creditBalance + amount)
            .clamp(0, CreditConstants.maxCreditBalance)
            .toInt(),
      );

      tx.set(
        walletRef,
        {
          ...updated.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(ledgerRef, {
        'type': 'refund',
        'amount': amount,
        'balanceAfter': updated.creditBalance,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return updated;
    });
  }

  Future<CreditState> addRewardedAdCredit(String deviceId) async {
    await _ensureWalletExists(deviceId);
    final today = AppDateUtils.todayKey();
    return _firestore.runTransaction((tx) async {
      final walletRef = _walletRef(deviceId);
      final ledgerRef = _ledgerRef(deviceId).doc();
      final snapshot = await tx.get(walletRef);
      final current = snapshot.data() != null
          ? CreditState.fromJson(snapshot.data()!)
          : const CreditState.empty();

      final watchedToday = current.lastAdRewardDate == today
          ? current.rewardedAdsWatchedToday
          : 0;

      if (watchedToday >= CreditConstants.maxRewardedAdsPerDay) {
        throw const RewardLimitException('Daily ad reward limit reached');
      }

      final newBalance =
          (current.creditBalance + CreditConstants.rewardedAdCredit)
              .clamp(0, CreditConstants.maxCreditBalance)
              .toInt();
      final earned = newBalance - current.creditBalance;
      final updated = current.copyWith(
        creditBalance: newBalance,
        lastAdRewardDate: today,
        rewardedAdsWatchedToday: watchedToday + 1,
        totalEarnedCredits: current.totalEarnedCredits + earned,
      );

      tx.set(
        walletRef,
        {
          ...updated.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (earned > 0) {
        tx.set(ledgerRef, {
          'type': 'rewarded_ad',
          'amount': earned,
          'balanceAfter': updated.creditBalance,
          'reason': 'rewarded_ad',
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {'date': today, 'watchedToday': watchedToday + 1},
        });
      }

      return updated;
    });
  }
}
