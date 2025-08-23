import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:logging/logging.dart';
import '../app_monitor.dart';
import '../websocket.dart';
import '../models/log_entry.dart';
import 'enhanced_logger.dart';
import 'service_event_bus.dart';
import 'service_health_monitor.dart';


@pragma('vm:entry-point')
class BackgroundServiceManager {
  static final _instance = BackgroundServiceManager._internal();
  factory BackgroundServiceManager() => _instance;
  BackgroundServiceManager._internal();
  
  final _eventBus = ServiceEventBus();
  final _healthMonitor = ServiceHealthMonitor();
  
  ServiceStatus _status = ServiceStatus.stopped;
  Timer? _heartbeatTimer;
  StreamSubscription? _serviceEventSubscription;
  
  
  ServiceStatus get status => _status;
  
  Future<void> initialize() async {
    EnhancedLogger.info(
      LogSource.service,
      LogCategory.system,
      'Initializing BackgroundServiceManager',
    );
    
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        isForegroundMode: false,
        onStart: onServiceStart,
      ),
      iosConfiguration: IosConfiguration(autoStart: true),
    );
    
    // Start the service after configuration
    final isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
      // ignore: avoid_print
      print('BackgroundServiceManager: Started background service');
    }
    
    _setupServiceListeners();
  }
  
  void _setupServiceListeners() {
    final service = FlutterBackgroundService();
    
    // Listen for service events from the background
    _serviceEventSubscription = service.on('serviceEvent').listen((event) {
      if (event != null) {
        try {
          final serviceEvent = ServiceEvent.fromJson(event);
          _eventBus.emit(serviceEvent);
        } catch (e) {
          EnhancedLogger.error(
            LogSource.service,
            LogCategory.system,
            'Failed to parse service event: $e',
          );
        }
      }
    });
    
    // Listen for health updates
    service.on('healthUpdate').listen((data) {
      if (data != null) {
        _handleHealthUpdate(data);
      }
    });
  }
  
  void _handleHealthUpdate(Map<String, dynamic> data) {
    final webSocketHealthy = data['webSocketHealthy'] as bool? ?? false;
    final monitoringHealthy = data['monitoringHealthy'] as bool? ?? false;
    
    _healthMonitor.updateWebSocketHealth(webSocketHealthy);
    _healthMonitor.updateMonitoringHealth(monitoringHealthy);
    _healthMonitor.reportHeartbeat();
  }
  
  @pragma('vm:entry-point')
  static Future<bool> onServiceStart(ServiceInstance service) async {
    // Set up logging for background service
    // Note: We don't redirect Logger.root to EnhancedLogger to avoid circular logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // Just print to console for debugging, don't use EnhancedLogger here
      // to avoid circular references
      // ignore: avoid_print
      print('BG ${record.level.name}: ${record.loggerName}: ${record.message}');
    });
    
    final manager = BackgroundServiceManager();
    manager._status = ServiceStatus.starting;
    
    EnhancedLogger.info(
      LogSource.service,
      LogCategory.system,
      'Background service starting...',
    );
    
    // Emit service started event
    manager._eventBus.emitSimple(ServiceEventType.serviceStarted, 'Service started successfully');
    
    // Set up service event handlers
    _setupServiceHandlers(service, manager);
    
    
    // Start app monitoring
    await _startAppMonitoring(manager);
    
    // Connect WebSocket
    _connectWebSocket(service, manager);
    
    // Start health monitoring
    manager._healthMonitor.startMonitoring();
    
    // Start heartbeat
    manager._startHeartbeat(service);
    
    manager._status = ServiceStatus.running;
    
    EnhancedLogger.info(
      LogSource.service,
      LogCategory.system,
      'Background service started successfully',
    );
    
    return true;
  }
  
  static void _setupServiceHandlers(ServiceInstance service, BackgroundServiceManager manager) {
    // Handle stop service
    service.on('stopService').listen((event) async {
      EnhancedLogger.info(
        LogSource.service,
        LogCategory.system,
        'Stop service event received',
      );
      
      manager._eventBus.emitSimple(ServiceEventType.serviceStopped, 'Service stopping');
      manager._healthMonitor.stopMonitoring();
      manager._heartbeatTimer?.cancel();
      
      closeWebSocket();
      stopAppMonitoring();
      service.stopSelf();
      
      manager._status = ServiceStatus.stopped;
      
      EnhancedLogger.info(
        LogSource.service,
        LogCategory.system,
        'Background service stopped',
      );
    });
    
    // Handle recovery request
    service.on('recover').listen((event) async {
      EnhancedLogger.info(
        LogSource.service,
        LogCategory.system,
        'Recovery request received',
      );
      
      manager._eventBus.emitSimple(ServiceEventType.recoveryAttempt, 'Attempting recovery');
      
      // Restart components
      await _restartComponents(service, manager);
    });
    
    // Handle component restart
    service.on('restartComponent').listen((event) async {
      if (event != null && event['component'] != null) {
        final component = event['component'] as String;
        await _restartComponent(component, service, manager);
      }
    });
    
    // Handle request for focus status - THIS RUNS IN BACKGROUND SERVICE
    service.on('requestFocusStatus').listen((event) async {
      // ignore: avoid_print
      print('BackgroundService: Received requestFocusStatus event in background isolate');
      
      EnhancedLogger.info(
        LogSource.service,
        LogCategory.system,
        'Focus status request received from UI',
      );
      
      // Request fresh status from WebSocket
      requestFocusStatus();
    });
  }
  
  static Future<void> _restartComponents(ServiceInstance service, BackgroundServiceManager manager) async {
    try {
      // Restart WebSocket
      closeWebSocket();
      await Future.delayed(const Duration(seconds: 1));
      _connectWebSocket(service, manager);
      
      // Restart monitoring
      stopAppMonitoring();
      await Future.delayed(const Duration(seconds: 1));
      await _startAppMonitoring(manager);
      
      EnhancedLogger.info(
        LogSource.service,
        LogCategory.system,
        'Components restarted successfully',
      );
    } catch (e) {
      EnhancedLogger.error(
        LogSource.service,
        LogCategory.system,
        'Failed to restart components: $e',
      );
    }
  }
  
  static Future<void> _restartComponent(String component, ServiceInstance service, BackgroundServiceManager manager) async {
    EnhancedLogger.info(
      LogSource.service,
      LogCategory.system,
      'Restarting component: $component',
    );
    
    try {
      switch (component) {
        case 'websocket':
          closeWebSocket();
          await Future.delayed(const Duration(seconds: 1));
          _connectWebSocket(service, manager);
          break;
        case 'monitor':
          stopAppMonitoring();
          await Future.delayed(const Duration(seconds: 1));
          await _startAppMonitoring(manager);
          break;
        default:
          EnhancedLogger.warning(
            LogSource.service,
            LogCategory.system,
            'Unknown component for restart: $component',
          );
      }
    } catch (e) {
      EnhancedLogger.error(
        LogSource.service,
        LogCategory.system,
        'Failed to restart $component: $e',
      );
    }
  }
  
  
  static Future<void> _startAppMonitoring(BackgroundServiceManager manager) async {
    try {
      await startAppMonitoring();
      manager._eventBus.emitSimple(ServiceEventType.monitoringStarted, 'App monitoring started');
      manager._healthMonitor.updateMonitoringHealth(true);
      
      EnhancedLogger.info(
        LogSource.monitor,
        LogCategory.monitoring,
        'App monitoring started successfully',
      );
    } catch (e) {
      manager._eventBus.emit(ServiceEvent(
        type: ServiceEventType.errorOccurred,
        message: 'Failed to start app monitoring',
        data: {'error': e.toString()},
      ));
      
      manager._healthMonitor.updateMonitoringHealth(false);
      
      EnhancedLogger.error(
        LogSource.monitor,
        LogCategory.monitoring,
        'Failed to start app monitoring: $e',
      );
    }
  }
  
  static void _connectWebSocket(
    ServiceInstance service,
    BackgroundServiceManager manager,
  ) {
    try {
      connectWebSocket(service);
      manager._eventBus.emitSimple(ServiceEventType.webSocketConnected, 'WebSocket connected');
      manager._healthMonitor.updateWebSocketHealth(true);
      
      EnhancedLogger.info(
        LogSource.webSocket,
        LogCategory.connection,
        'WebSocket connected successfully',
      );
    } catch (e) {
      manager._eventBus.emit(ServiceEvent(
        type: ServiceEventType.errorOccurred,
        message: 'Failed to connect WebSocket',
        data: {'error': e.toString()},
      ));
      
      manager._healthMonitor.updateWebSocketHealth(false);
      
      EnhancedLogger.error(
        LogSource.webSocket,
        LogCategory.connection,
        'Failed to connect WebSocket: $e',
      );
    }
  }
  
  void _startHeartbeat(ServiceInstance service) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _healthMonitor.reportHeartbeat();
      
      // Send health status to UI
      try {
        service.invoke('healthUpdate', {
          'webSocketHealthy': true, // Would be determined by actual WebSocket status
          'monitoringHealthy': true, // Would be determined by actual monitoring status
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Ignore MissingPluginException when UI isn't ready
        EnhancedLogger.debug(
          LogSource.service,
          LogCategory.health,
          'Could not send health update to UI: $e',
        );
      }
      
      EnhancedLogger.debug(
        LogSource.service,
        LogCategory.health,
        'Service heartbeat',
      );
    });
  }
  
  Future<void> stopService() async {
    EnhancedLogger.info(
      LogSource.service,
      LogCategory.system,
      'Stopping background service',
    );
    
    _eventBus.emitSimple(ServiceEventType.serviceStopped, 'Service stopping');
    _healthMonitor.stopMonitoring();
    _heartbeatTimer?.cancel();
    _serviceEventSubscription?.cancel();
    
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    
    _status = ServiceStatus.stopped;
  }
  
  Future<void> restartService() async {
    EnhancedLogger.info(
      LogSource.service,
      LogCategory.system,
      'Restarting background service',
    );
    
    await stopService();
    await Future.delayed(const Duration(seconds: 2));
    await initialize();
  }
  
  void dispose() {
    _heartbeatTimer?.cancel();
    _serviceEventSubscription?.cancel();
  }
}