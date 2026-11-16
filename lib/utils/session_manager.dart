import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'package:invoiceo/utils/saved_session.dart';

/// Signs the user out after the app has gone unused for [limit] (Settings → Automatic sign-out; 3 days unless
/// changed). Any tap or key press counts as use.
class SessionManager {
  static Timer? _timer;
  static VoidCallback? _onTimeout;
  static Duration _limit = const Duration(minutes: kAutoSignOutDefaultMinutes);
  static bool _sessionExpired = false;
  static bool _hooksAdded = false;

  // Idle time is counted twice: by the ticks of the timer, and by the clock. A computer that sleeps stops the
  // ticks but not the clock, so the sleep counts as unused time.
  static const _tick = Duration(seconds: 30);
  static Duration _idle = Duration.zero;
  static DateTime _lastUse = DateTime.now();

  // The last use is written to the saved sign-in at most this often.
  static const _saveEvery = Duration(minutes: 1);
  static DateTime? _lastSaved;

  /// Starts the session timer. Calls [onTimeout] when the session expires.
  static void initialize(void Function() onTimeout,
      {Duration limit = const Duration(minutes: kAutoSignOutDefaultMinutes)}) {
    _onTimeout = () {
      _sessionExpired = true;
      onTimeout();
    };
    _sessionExpired = false;
    _limit = limit;
    // App-wide hooks so any tap or key press counts as activity — including
    // dialogs, pushed screens and keyboard-only typing.
    if (!_hooksAdded) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
      HardwareKeyboard.instance.addHandler(_onKey);
      _hooksAdded = true;
    }
    _lastSaved = null;
    _resetTimer();
  }

  /// Changes the idle time allowed (the shop picked another one in Settings); counting starts again.
  static void setLimit(Duration limit) {
    _limit = limit;
    if (_onTimeout != null) _resetTimer();
  }

  /// The idle time allowed now.
  static Duration get limit => _limit;

  /// Resets the session timer (call on any user activity).
  static void onUserActivity() {
    if (_onTimeout == null) return;

    if (_sessionExpired) {
      _sessionExpired = false;
    }
    _resetTimer();
    _saveUse();
  }

  /// Cancels the timer and clears state.
  static void dispose() {
    _timer?.cancel();
    _timer = null;
    _onTimeout = null;
    if (_hooksAdded) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
      HardwareKeyboard.instance.removeHandler(_onKey);
      _hooksAdded = false;
    }
  }

  static void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) onUserActivity();
  }

  static bool _onKey(KeyEvent event) {
    onUserActivity();
    return false; // never consume the key
  }

  static void _resetTimer() {
    _timer?.cancel();
    _idle = Duration.zero;
    _lastUse = DateTime.now();
    _timer = Timer.periodic(_tick, (t) {
      _idle += _tick;
      if (_idle >= _limit || DateTime.now().difference(_lastUse) >= _limit) {
        t.cancel();
        _onTimeout?.call();
      }
    });
  }

  static void _saveUse() {
    final now = DateTime.now();
    final saved = _lastSaved;
    if (saved != null && now.difference(saved) < _saveEvery) return;
    _lastSaved = now;
    SavedSession.touch();
  }
}

// Re-export VoidCallback type alias so callers don't need dart:ui
typedef VoidCallback = void Function();
