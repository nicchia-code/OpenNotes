import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';

/// Signals that start a sync run by themselves (Model: operating-system, time).
enum SyncSignal {
  /// APP_RETURNED_TO_FOREGROUND: mobile back in the foreground, desktop window restored from minimized.
  appReturnedToForeground,

  /// NETWORK_AVAILABLE: the system reports a connection, also the state found at startup.
  networkAvailable,

  /// NETWORK_LOST: the system reports no connection.
  networkLost,

  /// SYNC_INTERVAL_ELAPSED: the periodic interval after the end of the last run has passed.
  syncIntervalElapsed,

  /// SYNC_RETRY_DUE: the scheduled wait after a failed run has ended.
  syncRetryDue,
}

/// Wait before the retry after the [failedInSeries]-th failed run in a row (0-based): 2 s, 5 s, 15 s, 30 s, then 60 s.
Duration syncRetryWait(int failedInSeries) {
  const waits = [Duration(seconds: 2), Duration(seconds: 5), Duration(seconds: 15), Duration(seconds: 30)];
  if (failedInSeries < waits.length) return waits[failedInSeries];
  return const Duration(seconds: 60);
}

/// Turns connectivity, visibility and timer events into [SyncSignal]s.
///
/// It owns the periodic interval and the retry wait: the sync run arms them when a run ends or fails.
/// It decides nothing else; the sync run decides what each signal does.
class SyncTriggers {
  SyncTriggers({
    required Stream<List<ConnectivityResult>> connectivityChanges,
    required Future<List<ConnectivityResult>> Function() checkConnectivity,
    required Stream<bool> visibilityChanges,
    required bool initiallyVisible,
    this.syncInterval = const Duration(seconds: 60),
  }) : _visible = initiallyVisible {
    _connectivitySub = connectivityChanges.listen((results) {
      _setOnline(_isOnline(results));
    });
    // The state found at startup counts only if no change has arrived before the check answers.
    unawaited(checkConnectivity().then((results) {
      if (_online == null) _setOnline(_isOnline(results));
    }));
    _visibilitySub = visibilityChanges.listen(_setVisible);
  }

  /// Time between the end of a run and the periodic signal.
  final Duration syncInterval;

  final _signals = StreamController<SyncSignal>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<bool>? _visibilitySub;
  Timer? _intervalTimer;
  Timer? _retryTimer;
  DateTime? _retryDueAt;
  bool? _online;
  bool _visible;

  Stream<SyncSignal> get signals => _signals.stream;

  /// When the scheduled retry is due, or null when no retry is waiting.
  DateTime? get retryDueAt => _retryDueAt;

  /// Whether the system reports no connection; false until the first answer.
  bool get isOffline => _online == false;

  /// Starts the [syncInterval] after the end of a run. A later call replaces the pending one.
  /// When it elapses, [SyncSignal.syncIntervalElapsed] is sent only if the app is visible and online and no retry waits.
  void armInterval() {
    _intervalTimer?.cancel();
    _intervalTimer = Timer(syncInterval, () {
      _intervalTimer = null;
      if (_visible && _online == true && _retryDueAt == null) _emit(SyncSignal.syncIntervalElapsed);
    });
  }

  void cancelInterval() {
    _intervalTimer?.cancel();
    _intervalTimer = null;
  }

  /// Waits [wait] after a failed run, then sends [SyncSignal.syncRetryDue]. Replaces any retry already waiting.
  void scheduleRetry(Duration wait) {
    cancelInterval();
    _retryTimer?.cancel();
    _retryDueAt = DateTime.now().add(wait);
    _retryTimer = Timer(wait, () {
      _retryTimer = null;
      _retryDueAt = null;
      _emit(SyncSignal.syncRetryDue);
    });
  }

  void cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryDueAt = null;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _visibilitySub?.cancel();
    cancelInterval();
    cancelRetry();
    _signals.close();
  }

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  void _setOnline(bool online) {
    if (online == _online) return;
    _online = online;
    if (online) {
      _emit(SyncSignal.networkAvailable);
      return;
    }
    // Offline: no attempt is made, so a pending retry or periodic run is dropped.
    cancelRetry();
    cancelInterval();
    _emit(SyncSignal.networkLost);
  }

  void _setVisible(bool visible) {
    if (visible == _visible) return;
    _visible = visible;
    if (visible) _emit(SyncSignal.appReturnedToForeground);
  }

  void _emit(SyncSignal signal) {
    if (!_signals.isClosed) _signals.add(signal);
  }
}

/// Whether the app is visible: on mobile and web by the lifecycle (in the foreground),
/// on desktop by the window (not minimized to an icon).
class AppVisibility with WindowListener {
  AppVisibility() {
    if (_isDesktop) {
      windowManager.addListener(this);
    } else {
      _lifecycle = AppLifecycleListener(
        onStateChange: (state) => _set(state == AppLifecycleState.resumed),
      );
    }
  }

  static bool get _isDesktop => !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  final _changes = StreamController<bool>.broadcast();
  AppLifecycleListener? _lifecycle;
  bool _visible = true;

  bool get isVisible => _visible;

  /// Sends each change of visibility.
  Stream<bool> get changes => _changes.stream;

  @override
  void onWindowMinimize() => _set(false);

  @override
  void onWindowRestore() => _set(true);

  void _set(bool visible) {
    if (visible == _visible) return;
    _visible = visible;
    _changes.add(visible);
  }

  void dispose() {
    if (_isDesktop) windowManager.removeListener(this);
    _lifecycle?.dispose();
    _changes.close();
  }
}
