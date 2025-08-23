import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_entry.dart';
import 'enhanced_logger.dart';

enum ServiceEventType {
  serviceStarted,
  serviceStopped,
  serviceHealthCheck,
  webSocketConnected,
  webSocketDisconnected,
  webSocketReconnecting,
  webSocketMessage,
  monitoringStarted,
  monitoringStopped,
  appDetected,
  overlayShown,
  overlayHidden,
  focusStateChanged,
  errorOccurred,
  recoveryAttempt,
  memoryWarning,
}

class ServiceEvent {
  final ServiceEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final String? message;
  
  ServiceEvent({
    required this.type,
    DateTime? timestamp,
    this.data,
    this.message,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'timestamp': timestamp.toIso8601String(),
    'data': data,
    'message': message,
  };
  
  factory ServiceEvent.fromJson(Map<String, dynamic> json) {
    return ServiceEvent(
      type: ServiceEventType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'],
      message: json['message'],
    );
  }
}

class ServiceEventBus {
  static final _instance = ServiceEventBus._internal();
  factory ServiceEventBus() => _instance;
  ServiceEventBus._internal();
  
  final _eventController = StreamController<ServiceEvent>.broadcast();
  final _eventHistory = <ServiceEvent>[];
  static const int _maxHistorySize = 100;
  
  Stream<ServiceEvent> get events => _eventController.stream;
  List<ServiceEvent> get history => List.unmodifiable(_eventHistory);
  
  void emit(ServiceEvent event) {
    _eventController.add(event);
    _addToHistory(event);
    _logEvent(event);
  }
  
  void emitSimple(ServiceEventType type, [String? message, Map<String, dynamic>? data]) {
    emit(ServiceEvent(
      type: type,
      message: message,
      data: data,
    ));
  }
  
  void _addToHistory(ServiceEvent event) {
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeAt(0);
    }
  }
  
  void _logEvent(ServiceEvent event) {
    final logLevel = _getLogLevelForEvent(event.type);
    EnhancedLogger.log(
      level: logLevel,
      source: LogSource.system,
      category: LogCategory.event,
      message: 'Event: ${event.type.name} - ${event.message ?? 'No message'}',
      metadata: event.data,
    );
  }
  
  LogLevel _getLogLevelForEvent(ServiceEventType type) {
    switch (type) {
      case ServiceEventType.errorOccurred:
      case ServiceEventType.memoryWarning:
        return LogLevel.error;
      case ServiceEventType.webSocketDisconnected:
      case ServiceEventType.recoveryAttempt:
        return LogLevel.warning;
      case ServiceEventType.serviceStarted:
      case ServiceEventType.serviceStopped:
      case ServiceEventType.webSocketConnected:
      case ServiceEventType.monitoringStarted:
        return LogLevel.info;
      default:
        return LogLevel.debug;
    }
  }
  
  
  Stream<ServiceEvent> filterEvents(ServiceEventType type) {
    return events.where((event) => event.type == type);
  }
  
  Stream<ServiceEvent> filterMultipleEvents(List<ServiceEventType> types) {
    return events.where((event) => types.contains(event.type));
  }
  
  ServiceEvent? getLastEventOfType(ServiceEventType type) {
    try {
      return _eventHistory.lastWhere((event) => event.type == type);
    } catch (_) {
      return null;
    }
  }
  
  List<ServiceEvent> getEventsInRange(DateTime start, DateTime end) {
    return _eventHistory.where((event) => 
      event.timestamp.isAfter(start) && event.timestamp.isBefore(end)
    ).toList();
  }
  
  void clearHistory() {
    _eventHistory.clear();
  }
  
  void dispose() {
    _eventController.close();
  }
}

// Service Health Status
enum ServiceStatus {
  starting,
  running,
  degraded,
  failed,
  stopped,
}

class ServiceHealthStatus {
  final ServiceStatus status;
  final DateTime lastHealthCheck;
  final bool webSocketConnected;
  final bool monitoringActive;
  final int errorCount;
  final double memoryUsageMB;
  final String? lastError;
  
  ServiceHealthStatus({
    required this.status,
    required this.lastHealthCheck,
    required this.webSocketConnected,
    required this.monitoringActive,
    required this.errorCount,
    required this.memoryUsageMB,
    this.lastError,
  });
  
  ServiceHealthStatus copyWith({
    ServiceStatus? status,
    DateTime? lastHealthCheck,
    bool? webSocketConnected,
    bool? monitoringActive,
    int? errorCount,
    double? memoryUsageMB,
    String? lastError,
  }) {
    return ServiceHealthStatus(
      status: status ?? this.status,
      lastHealthCheck: lastHealthCheck ?? this.lastHealthCheck,
      webSocketConnected: webSocketConnected ?? this.webSocketConnected,
      monitoringActive: monitoringActive ?? this.monitoringActive,
      errorCount: errorCount ?? this.errorCount,
      memoryUsageMB: memoryUsageMB ?? this.memoryUsageMB,
      lastError: lastError ?? this.lastError,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'status': status.toString(),
    'lastHealthCheck': lastHealthCheck.toIso8601String(),
    'webSocketConnected': webSocketConnected,
    'monitoringActive': monitoringActive,
    'errorCount': errorCount,
    'memoryUsageMB': memoryUsageMB,
    'lastError': lastError,
  };
}

// Providers
final serviceEventBusProvider = Provider<ServiceEventBus>((ref) {
  final bus = ServiceEventBus();
  ref.onDispose(() => bus.dispose());
  return bus;
});

final serviceEventsProvider = StreamProvider<ServiceEvent>((ref) {
  final bus = ref.watch(serviceEventBusProvider);
  return bus.events;
});

final serviceEventHistoryProvider = Provider<List<ServiceEvent>>((ref) {
  final bus = ref.watch(serviceEventBusProvider);
  return bus.history;
});

// Health status provider
final serviceHealthStatusProvider = StateNotifierProvider<ServiceHealthNotifier, ServiceHealthStatus>((ref) {
  return ServiceHealthNotifier(ref);
});

class ServiceHealthNotifier extends StateNotifier<ServiceHealthStatus> {
  final Ref _ref;
  StreamSubscription<ServiceEvent>? _eventSubscription;
  
  ServiceHealthNotifier(this._ref) : super(ServiceHealthStatus(
    status: ServiceStatus.stopped,
    lastHealthCheck: DateTime.now(),
    webSocketConnected: false,
    monitoringActive: false,
    errorCount: 0,
    memoryUsageMB: 0,
  )) {
    _listenToEvents();
  }
  
  void _listenToEvents() {
    final bus = _ref.read(serviceEventBusProvider);
    _eventSubscription = bus.events.listen((event) {
      switch (event.type) {
        case ServiceEventType.serviceStarted:
          state = state.copyWith(status: ServiceStatus.running);
          break;
        case ServiceEventType.serviceStopped:
          state = state.copyWith(status: ServiceStatus.stopped);
          break;
        case ServiceEventType.serviceHealthCheck:
          final data = event.data;
          if (data != null) {
            state = state.copyWith(
              lastHealthCheck: DateTime.now(),
              memoryUsageMB: data['memoryMB'] ?? state.memoryUsageMB,
            );
          }
          break;
        case ServiceEventType.webSocketConnected:
          state = state.copyWith(webSocketConnected: true);
          break;
        case ServiceEventType.webSocketDisconnected:
          state = state.copyWith(webSocketConnected: false);
          break;
        case ServiceEventType.monitoringStarted:
          state = state.copyWith(monitoringActive: true);
          break;
        case ServiceEventType.monitoringStopped:
          state = state.copyWith(monitoringActive: false);
          break;
        case ServiceEventType.errorOccurred:
          state = state.copyWith(
            errorCount: state.errorCount + 1,
            lastError: event.message,
            status: state.errorCount > 5 ? ServiceStatus.degraded : state.status,
          );
          break;
        case ServiceEventType.recoveryAttempt:
          state = state.copyWith(
            status: ServiceStatus.running,
            errorCount: 0,
          );
          break;
        default:
          break;
      }
    });
  }
  
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}