import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';

/// Runs only the most recent callback after a period of inactivity.
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback callback, {Duration? overrideDelay}) {
    _timer?.cancel();
    _timer = Timer(overrideDelay ?? delay, callback);
  }

  void dispose() => _timer?.cancel();
}

/// Performance utilities for optimizing UI operations
class PerformanceUtils {
  /// Throttle utility to limit function call frequency
  static final Map<String, DateTime> _lastThrottleCall = {};

  static bool throttle(String key, Duration minInterval) {
    final now = DateTime.now();
    final lastCall = _lastThrottleCall[key];

    if (lastCall == null || now.difference(lastCall) >= minInterval) {
      _lastThrottleCall[key] = now;
      return true;
    }
    return false;
  }

  /// Post frame callback wrapper for safe UI updates
  static void postFrame(VoidCallback callback) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => callback());
    } else {
      callback();
    }
  }

  /// Dispose utility for cleaning up resources
  static void safeDispose(dynamic resource) {
    try {
      if (resource is Timer && resource.isActive) {
        resource.cancel();
      } else if (resource is StreamSubscription) {
        resource.cancel();
      } else if (resource?.dispose != null) {
        resource.dispose();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Warning: Error disposing resource: $e');
      }
    }
  }

  /// Clean up all static resources
  static void cleanup() {
    _lastThrottleCall.clear();
  }
}

/// Mixin for ViewModels to add performance optimizations
mixin PerformanceOptimizedViewModel on ChangeNotifier {
  final Debouncer _notifyDebouncer =
      Debouncer(const Duration(milliseconds: 16));
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  bool _disposed = false;

  /// Track subscription for proper disposal
  void trackSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Track timer for proper disposal
  void trackTimer(Timer timer) {
    _timers.add(timer);
  }

  /// Debounced notifyListeners to prevent excessive rebuilds
  void notifyListenersDebounced(
      [Duration delay = const Duration(milliseconds: 16)]) {
    if (_disposed) return;
    _notifyDebouncer.run(() {
      if (!_disposed) {
        notifyListeners();
      }
    }, overrideDelay: delay);
  }

  /// Throttled notifyListeners
  void notifyListenersThrottled(String key,
      [Duration minInterval = const Duration(milliseconds: 100)]) {
    if (_disposed) return;
    if (PerformanceUtils.throttle(key, minInterval)) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyDebouncer.dispose();

    // Clean up all tracked resources
    for (final subscription in _subscriptions) {
      PerformanceUtils.safeDispose(subscription);
    }
    _subscriptions.clear();

    for (final timer in _timers) {
      PerformanceUtils.safeDispose(timer);
    }
    _timers.clear();

    super.dispose();
  }
}
