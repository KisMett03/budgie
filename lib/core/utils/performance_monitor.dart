import 'dart:developer' as developer;
import 'dart:async';

/// 性能监控工具类
///
/// 用于监控应用程序的性能指标，如操作执行时间等
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<int>> _historicalData = {};

  /// 开始计时
  ///
  /// [key] 计时器标识
  static void startTimer(String key) {
    _timers[key] = Stopwatch()..start();
  }

  /// 停止计时并记录结果
  ///
  /// [key] 计时器标识
  /// [logResult] 是否打印结果
  /// 返回耗时（毫秒）
  static int stopTimer(String key, {bool logResult = true}) {
    final timer = _timers[key];
    if (timer == null) {
      if (logResult) {
        developer.log('Timer "$key" not found', name: 'PerformanceMonitor');
      }
      return 0;
    }

    timer.stop();
    final elapsed = timer.elapsedMilliseconds;
    _timers.remove(key);

    // 记录历史数据
    if (!_historicalData.containsKey(key)) {
      _historicalData[key] = [];
    }
    _historicalData[key]!.add(elapsed);

    if (logResult) {
      developer.log('$key took ${elapsed}ms', name: 'PerformanceMonitor');
    }

    return elapsed;
  }

  /// 获取指定操作的平均执行时间
  ///
  /// [key] 操作标识
  /// 返回平均执行时间（毫秒）
  static double getAverageTime(String key) {
    final data = _historicalData[key];
    if (data == null || data.isEmpty) {
      return 0;
    }

    final sum = data.fold(0, (sum, time) => sum + time);
    return sum / data.length;
  }

  /// 获取指定操作的最长执行时间
  ///
  /// [key] 操作标识
  /// 返回最长执行时间（毫秒）
  static int getMaxTime(String key) {
    final data = _historicalData[key];
    if (data == null || data.isEmpty) {
      return 0;
    }

    return data.reduce((max, time) => max > time ? max : time);
  }

  /// 记录性能日志
  ///
  /// [message] 日志消息
  /// [elapsedTime] 耗时（毫秒）
  static void logPerformance(String message, int elapsedTime) {
    developer.log('$message: ${elapsedTime}ms', name: 'PerformanceMonitor');
  }

  /// 包装函数以测量其执行时间
  ///
  /// [key] 操作标识
  /// [function] 要执行的函数
  /// 返回函数的执行结果
  static T measure<T>(String key, T Function() function) {
    startTimer(key);
    final result = function();
    stopTimer(key);
    return result;
  }

  /// 包装异步函数以测量其执行时间
  ///
  /// [key] 操作标识
  /// [function] 要执行的异步函数
  /// 返回包含函数执行结果的Future
  static Future<T> measureAsync<T>(
      String key, Future<T> Function() function) async {
    startTimer(key);
    try {
      final result = await function();
      stopTimer(key);
      return result;
    } catch (e) {
      stopTimer(key);
      rethrow;
    }
  }

  /// 清除所有历史数据
  static void clearHistoricalData() {
    _historicalData.clear();
  }
}
