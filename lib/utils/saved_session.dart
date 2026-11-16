import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/models/user.dart';
import 'package:invoiceo/repositories/auth_repository.dart';

/// How long the app may sit unused before it asks for the password again, in minutes. The shop picks one in
/// Settings; the default is 3 days.
const int kAutoSignOutDefaultMinutes = 3 * 24 * 60;

/// The ready-made choices in Settings, shortest first. "Custom" takes any time between [kAutoSignOutMinMinutes]
/// and [kAutoSignOutMaxMinutes].
const List<int> kAutoSignOutChoices = [30, 60, 120, 240, 480, 24 * 60, 3 * 24 * 60];

/// The shortest time allowed: less would sign people out while they work.
const int kAutoSignOutMinMinutes = 5;

/// The longest time allowed, 30 days: more is not really a sign-out.
const int kAutoSignOutMaxMinutes = 30 * 24 * 60;

/// Whether [minutes] is a time the app accepts.
bool isValidAutoSignOutMinutes(int minutes) =>
    minutes >= kAutoSignOutMinMinutes && minutes <= kAutoSignOutMaxMinutes;

/// The saved setting as minutes: anything outside 5 minutes to 30 days (or not a number) gives the default.
int parseAutoSignOutMinutes(String? saved) {
  final v = int.tryParse((saved ?? '').trim());
  return v != null && isValidAutoSignOutMinutes(v) ? v : kAutoSignOutDefaultMinutes;
}

/// The signed-in user, remembered on this computer so the app opens straight in when it was last used
/// less than the chosen time ago. Kept in the computer's own preferences (not in the company database), so
/// a backup restored on another computer never signs anyone in. It holds the user's id, a stamp of the saved
/// password (never the password) and the time of the last use; one record, for the company database that
/// was open.
class SavedSession {
  static const _kUser = 'session_user_id';
  static const _kStamp = 'session_stamp';
  static const _kDb = 'session_db';
  static const _kLastActive = 'session_last_active';

  /// Changes whenever the user's password does, so a reset password ends the saved sign-in.
  static String stampOf(User user) =>
      sha256.convert(utf8.encode('${user.id}|${user.password}|${user.salt ?? ''}')).toString();

  /// The clock; tests replace it.
  static DateTime Function() now = DateTime.now;

  static Future<void> save(User user) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kUser, user.id);
      await p.setString(_kStamp, stampOf(user));
      await p.setString(_kDb, DatabaseHelper.path ?? '');
      await p.setInt(_kLastActive, now().millisecondsSinceEpoch);
    } catch (_) {
      // Staying signed in is a convenience; never block the sign-in.
    }
  }

  /// Records that the app is in use now (only when someone is signed in).
  static Future<void> touch() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getString(_kUser) == null) return;
      await p.setInt(_kLastActive, now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Forgets the sign-in (Logout, an expired session).
  static Future<void> clear() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kUser);
      await p.remove(_kStamp);
      await p.remove(_kDb);
      await p.remove(_kLastActive);
    } catch (_) {}
  }

  /// The user to open the app as, or null when the Login screen must be shown: nobody saved, another company
  /// database, unused for [limitMinutes] or more, a clock set back, the user gone, their password changed, or a
  /// password change still due.
  static Future<User?> restore(AuthRepository auth, int limitMinutes) async {
    try {
      final p = await SharedPreferences.getInstance();
      final id = p.getString(_kUser);
      final last = p.getInt(_kLastActive);
      if (id == null || last == null) return null;
      if ((p.getString(_kDb) ?? '') != (DatabaseHelper.path ?? '')) return null;
      final idle = now().difference(DateTime.fromMillisecondsSinceEpoch(last));
      if (idle >= Duration(minutes: limitMinutes)) return null;
      if (idle < const Duration(minutes: -5)) return null; // the clock was set back
      final user = await auth.getUserById(id);
      if (user == null || !user.passwordChanged) return null;
      if (stampOf(user) != p.getString(_kStamp)) return null;
      return user;
    } catch (_) {
      return null;
    }
  }
}
