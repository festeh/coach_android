import 'dart:async';
import 'dart:io';
import '../models/log_entry.dart';
import 'enhanced_logger.dart';
import 'service_event_bus.dart';
import '../app_monitor.dart' as app_monitor;

class ServiceHealthMonitor {
  static final _instance = ServiceHealthMonitor._internal();
  factory ServiceHealthMonitor() => _instance;
  ServiceHealthMonitor._internal() {
    _setupEventListeners();
  }
  
  Timer? _healthCheckTimer;
  Timer? _watchdogTimer;
  DateTime? _lastHeartbeat;
  int _failedHealthChecks = 0;
  static const int _maxFailedChecks = 3;
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _watchdogTimeout = Duration(minutes: 2);
  
  bool _isWebSocketHealthy = false;
  bool _isMonitoringHealthy = false;
  bool _isServiceResponding = true;
  
  final _eventBus = ServiceEventBus();
  
  void _setupEventListeners() {
    _eventBus.events.listen((event) {
      switch (event.type) {
        case ServiceEventType.webSocketConnected:
          updateWebSocketHealth(true);
          break;
        case ServiceEventType.webSocketDisconnected:
          updateWebSocketHealth(false);
          break;
        default:
          break;
      }
    });
  }
  
  void startMonitoring() {
    EnhancedLogger.info(
      LogSource.system,
      LogCategory.health,
      'Starting service health monitoring',
    );
    
    _startHealthCheckTimer();
    _startWatchdogTimer();
    _eventBus.emitSimple(ServiceEventType.serviceHealthCheck, 'Health monitoring started');
  }
  
  void stopMonitoring() {
    EnhancedLogger.info(
      LogSource.system,
      LogCategory.health,
      'Stopping service health monitoring',
    );
    
    _healthCheckTimer?.cancel();
    _watchdogTimer?.cancel();
    _healthCheckTimer = null;
    _watchdogTimer = null;
  }
  
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }
  
  void _startWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(_watchdogTimeout, (_) {
      _checkWatchdog();
    });
  }
  
  Future<void> _performHealthCheck() async {
    try {
      // Check memory usage
      final memoryMB = await _getMemoryUsage();
      
      // Check if service is responding
      final serviceRunning = await _checkServiceRunning();
      
      // Calculate overall health
      final isHealthy = _isWebSocketHealthy && 
                        _isMonitoringHealthy && 
                        _isServiceResponding &&
                        serviceRunning;
      
      if (isHealthy) {
        _failedHealthChecks = 0;
        _lastHeartbeat = DateTime.now();
        
        _eventBus.emit(ServiceEvent(
          type: ServiceEventType.serviceHealthCheck,
          message: 'Service healthy',
          data: {
            'memoryMB': memoryMB,
            'webSocketHealthy': _isWebSocketHealthy,
            'monitoringHealthy': _isMonitoringHealthy,
            'serviceResponding': _isServiceResponding,
          },
        ));
        
        EnhancedLogger.debug(
          LogSource.system,
          LogCategory.health,
          'Health check passed',
          {
            'memoryMB': memoryMB,
            'components': {
              'webSocket': _isWebSocketHealthy,
              'monitoring': _isMonitoringHealthy,
              'service': _isServiceResponding,
            },
          },
        );
      } else {
        _failedHealthChecks++;
        
        EnhancedLogger.warning(
          LogSource.system,
          LogCategory.health,
          'Health check failed',
          {
            'failedChecks': _failedHealthChecks,
            'maxAllowed': _maxFailedChecks,
            'components': {
              'webSocket': _isWebSocketHealthy,
              'monitoring': _isMonitoringHealthy,
              'service': _isServiceResponding,
            },
          },
        );
        
        if (_failedHealthChecks >= _maxFailedChecks) {
          await _handleServiceFailure();
        }
      }
      
      // Check memory warning
      if (memoryMB > 100) {
        _eventBus.emit(ServiceEvent(
          type: ServiceEventType.memoryWarning,
          message: 'High memory usage detected',
          data: {'memoryMB': memoryMB},
        ));
        
        EnhancedLogger.warning(
          LogSource.system,
          LogCategory.health,
          'High memory usage: ${memoryMB.toStringAsFixed(2)} MB',
        );
      }
      
    } catch (e, stack) {
      EnhancedLogger.error(
        LogSource.system,
        LogCategory.health,
        'Health check error: $e',
        null,
        stack.toString(),
      );
    }
  }
  
  void _checkWatchdog() {
    if (_lastHeartbeat == null) {
      return;
    }
    
    final timeSinceLastHeartbeat = DateTime.now().difference(_lastHeartbeat!);
    if (timeSinceLastHeartbeat > _watchdogTimeout) {
      EnhancedLogger.critical(
        LogSource.system,
        LogCategory.health,
        'Watchdog timeout - service appears frozen',
        {'lastHeartbeat': _lastHeartbeat?.toIso8601String()},
      );
      
      _eventBus.emit(ServiceEvent(
        type: ServiceEventType.errorOccurred,
        message: 'Service watchdog timeout',
        data: {'lastHeartbeat': _lastHeartbeat?.toIso8601String()},
      ));
      
      _attemptRecovery();
    }
  }
  
  Future<void> _handleServiceFailure() async {
    EnhancedLogger.error(
      LogSource.system,
      LogCategory.health,
      'Service health check failed $_maxFailedChecks times - attempting recovery',
    );
    
    _eventBus.emit(ServiceEvent(
      type: ServiceEventType.errorOccurred,
      message: 'Service health critically degraded',
      data: {
        'failedChecks': _failedHealthChecks,
        'webSocketHealthy': _isWebSocketHealthy,
        'monitoringHealthy': _isMonitoringHealthy,
      },
    ));
    
    await _attemptRecovery();
  }
  
  Future<void> _attemptRecovery() async {
    EnhancedLogger.info(
      LogSource.system,
      LogCategory.health,
      'Attempting service recovery',
    );
    
    _eventBus.emit(ServiceEvent(
      type: ServiceEventType.recoveryAttempt,
      message: 'Starting recovery procedure',
    ));
    
    try {
      // Reset failed checks counter
      _failedHealthChecks = 0;
      
      EnhancedLogger.info(
        LogSource.service,
        LogCategory.health,
        'Attempting service recovery...',
      );
      
      // Attempt to restart the monitoring service
      await _attemptServiceRestart();
      
      // WebSocket has its own reconnection logic, so we don't need to handle it here
      
      // Wait a moment for service to initialize
      await Future.delayed(const Duration(seconds: 3));
      
      // Verify the service is actually running
      final isRecovered = await _verifyServiceHealth();
      
      if (isRecovered) {
        EnhancedLogger.info(
          LogSource.system,
          LogCategory.health,
          'Service recovery successful',
        );
        
        _eventBus.emit(ServiceEvent(
          type: ServiceEventType.serviceStarted,
          message: 'Service recovered successfully',
        ));
      } else {
        throw Exception('Service recovery verification failed');
      }
    } catch (e, stack) {
      EnhancedLogger.critical(
        LogSource.system,
        LogCategory.health,
        'Recovery attempt failed: $e',
        null,
        stack.toString(),
      );
    }
  }
  
  Future<double> _getMemoryUsage() async {
    try {
      final info = ProcessInfo.currentRss;
      return info / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0;
    }
  }
  
  Future<bool> _checkServiceRunning() async {
    try {
      // Check various health indicators
      final now = DateTime.now();
      
      // Check if we have recent heartbeat (service is responding)
      if (_lastHeartbeat != null) {
        final timeSinceHeartbeat = now.difference(_lastHeartbeat!);
        if (timeSinceHeartbeat.inMinutes < 5) { // Service responded within 5 minutes
          return true;
        }
      }
      
      // Check component health
      if (_isWebSocketHealthy && _isMonitoringHealthy && _isServiceResponding) {
        return true;
      }
      
      // If no recent heartbeat and components aren't healthy, consider it down
      return false;
    } catch (e) {
      return false;
    }
  }
  
  void updateWebSocketHealth(bool isHealthy) {
    _isWebSocketHealthy = isHealthy;
    if (isHealthy) {
      _lastHeartbeat = DateTime.now();
    }
  }
  
  void updateMonitoringHealth(bool isHealthy) {
    _isMonitoringHealthy = isHealthy;
    if (isHealthy) {
      _lastHeartbeat = DateTime.now();
    }
  }
  
  void reportHeartbeat() {
    _lastHeartbeat = DateTime.now();
    _isServiceResponding = true;
  }
  
  Map<String, dynamic> getHealthStatus() {
    return {
      'isHealthy': _failedHealthChecks == 0,
      'failedChecks': _failedHealthChecks,
      'lastHeartbeat': _lastHeartbeat?.toIso8601String(),
      'components': {
        'webSocket': _isWebSocketHealthy,
        'monitoring': _isMonitoringHealthy,
        'serviceResponding': _isServiceResponding,
      },
    };
  }
  
  
  /// Attempts to restart the monitoring service
  Future<void> _attemptServiceRestart() async {
    try {
      // Stop current monitoring if running
      await app_monitor.stopAppMonitoring();
      
      // Wait a moment before restarting
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Restart the app monitoring service
      await app_monitor.startAppMonitoring();
      
      EnhancedLogger.info(
        LogSource.service,
        LogCategory.health,
        'Service restart attempt completed',
      );
    } catch (e) {
      EnhancedLogger.warning(
        LogSource.service,
        LogCategory.health,
        'Service restart attempt failed: $e',
      );
      rethrow;
    }
  }
  
  /// Verifies that the service is healthy after recovery attempt
  Future<bool> _verifyServiceHealth() async {
    try {
      // Perform multiple health checks to verify recovery
      var healthyChecks = 0;
      const checksNeeded = 3;
      
      for (int i = 0; i < checksNeeded; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check if the service is responding
        final isResponding = await _checkServiceRunning();
        if (isResponding) {
          healthyChecks++;
        }
        
        // Check WebSocket health if applicable
        if (_isWebSocketHealthy) {
          healthyChecks++;
        }
      }
      
      // Consider recovery successful if most checks pass
      final isHealthy = healthyChecks >= (checksNeeded * 0.6);
      
      EnhancedLogger.info(
        LogSource.system,
        LogCategory.health,
        'Service health verification: $healthyChecks/$checksNeeded checks passed, healthy: $isHealthy',
      );
      
      return isHealthy;
    } catch (e) {
      EnhancedLogger.error(
        LogSource.system,
        LogCategory.health,
        'Service health verification failed: $e',
      );
      return false;
    }
  }
}