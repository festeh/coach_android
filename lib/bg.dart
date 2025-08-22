import 'package:flutter_background_service/flutter_background_service.dart';
import 'services/background_service_manager.dart';
import 'services/enhanced_logger.dart';
import 'models/log_entry.dart';

/// Initialize the background service with enhanced management
Future<void> initBgService() async {
  EnhancedLogger.info(
    LogSource.service,
    LogCategory.system,
    'Initializing background service',
  );
  
  final manager = BackgroundServiceManager();
  await manager.initialize();
  
  EnhancedLogger.info(
    LogSource.service,
    LogCategory.system,
    'Background service initialization complete',
  );
}

/// Entry point for the background service
/// This is called by the BackgroundServiceManager
@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  return BackgroundServiceManager.onServiceStart(service);
}