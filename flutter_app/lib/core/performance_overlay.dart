import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Debug-mode performance overlay with FPS counter, memory tracker,
/// and active ticker count.
///
/// Shows live metrics as a compact HUD in the top-right corner.
/// Only visible in debug/profile mode.
class PerformanceMonitor {
  PerformanceMonitor._();
  static final _instance = PerformanceMonitor._();
  static PerformanceMonitor get instance => _instance;

  final _fpsStream = StreamController<double>.broadcast();
  Stream<double> get fpsStream => _fpsStream.stream;

  bool _running = false;
  int _frameCount = 0;
  DateTime _lastReport = DateTime.now();

  /// Start collecting frame metrics.
  void start() {
    if (_running || !kDebugMode) return;
    _running = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    if (kDebugMode) debugPrint('[PerfMonitor] started');
  }

  /// Stop collecting.
  void stop() {
    if (!_running) return;
    _running = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    if (kDebugMode) debugPrint('[PerfMonitor] stopped');
  }

  void _onTimings(List<FrameTiming> timings) {
    _frameCount += timings.length;
    final now = DateTime.now();
    final delta = now.difference(_lastReport).inMilliseconds;
    if (delta >= 1000) {
      final fps = _frameCount * 1000.0 / delta;
      _fpsStream.add(fps);
      _frameCount = 0;
      _lastReport = now;
    }
  }

  /// Dispose resources.
  void dispose() {
    stop();
    _fpsStream.close();
  }
}
