import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/log_entry.dart';
import '../services/enhanced_logger.dart';
import '../services/service_event_bus.dart';
import 'package:intl/intl.dart';

class LogsView extends ConsumerStatefulWidget {
  const LogsView({super.key});

  @override
  ConsumerState<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends ConsumerState<LogsView> {
  List<LogEntry> _logs = [];
  List<LogEntry> _filteredLogs = [];
  bool _isLoading = true;
  StreamSubscription<LogEntry>? _logStreamSubscription;
  
  // Filter states
  LogLevel? _selectedLevel;
  LogSource? _selectedSource;
  LogCategory? _selectedCategory;
  String _searchQuery = '';
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadLogs();
    _setupLogStream();
  }
  
  @override
  void dispose() {
    _logStreamSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    final logs = await EnhancedLogger.getLogs();
    
    if (mounted) {
      setState(() {
        _logs = logs;
        _applyFilters();
        _isLoading = false;
      });
    }
  }
  
  void _setupLogStream() {
    _logStreamSubscription = EnhancedLogger.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.insert(0, log);
          if (_logs.length > 500) {
            _logs.removeLast();
          }
          _applyFilters();
        });
        
        if (_autoScroll && _scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }
  
  void _applyFilters() {
    _filteredLogs = _logs.where((log) {
      // Level filter
      if (_selectedLevel != null && log.level.priority < _selectedLevel!.priority) {
        return false;
      }
      
      // Source filter
      if (_selectedSource != null && log.source != _selectedSource) {
        return false;
      }
      
      // Category filter
      if (_selectedCategory != null && log.category != _selectedCategory) {
        return false;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return log.message.toLowerCase().contains(query) ||
               (log.metadata?.toString().toLowerCase().contains(query) ?? false);
      }
      
      return true;
    }).toList();
  }
  
  Future<void> _clearLogs() async {
    await EnhancedLogger.clearLogs();
    await _loadLogs();
  }
  
  Future<void> _exportLogs() async {
    final logsText = await EnhancedLogger.exportLogs(
      minLevel: _selectedLevel,
      source: _selectedSource,
      category: _selectedCategory,
    );
    
    await Clipboard.setData(ClipboardData(text: logsText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logs exported to clipboard',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final healthStatus = ref.watch(serviceHealthStatusProvider);
    
    return Scaffold(
      body: Column(
        children: [
          _buildServiceStatusBar(healthStatus),
          _buildFilterBar(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildLogsList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServiceStatusBar(ServiceHealthStatus healthStatus) {
    final statusColor = _getStatusColor(healthStatus.status);
    final statusText = _getStatusText(healthStatus.status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: statusColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Service: $statusText',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          const Spacer(),
          if (healthStatus.webSocketConnected)
            _buildIndicator('WS', Colors.green)
          else
            _buildIndicator('WS', Colors.red),
          const SizedBox(width: 8),
          if (healthStatus.monitoringActive)
            _buildIndicator('Monitor', Colors.green)
          else
            _buildIndicator('Monitor', Colors.red),
          const SizedBox(width: 8),
          Text(
            'Errors: ${healthStatus.errorCount}',
            style: TextStyle(
              fontSize: 12,
              color: healthStatus.errorCount > 0 ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndicator(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              'Level',
              _selectedLevel?.displayName,
              () => _showLevelPicker(),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFilterChip(
              'Source',
              _selectedSource?.displayName,
              () => _showSourcePicker(),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFilterChip(
              'Category',
              _selectedCategory?.displayName,
              () => _showCategoryPicker(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Filters',
            onPressed: () {
              setState(() {
                _selectedLevel = null;
                _selectedSource = null;
                _selectedCategory = null;
                _searchQuery = '';
                _searchController.clear();
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value != null
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                  color: value != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: value != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.lock_outline : Icons.lock_open,
              color: _autoScroll 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            tooltip: _autoScroll ? 'Auto-scroll enabled' : 'Auto-scroll disabled',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'refresh':
                  await _loadLogs();
                  break;
                case 'export':
                  await _exportLogs();
                  break;
                case 'clear':
                  final confirm = await _showClearConfirmation();
                  if (confirm == true) {
                    await _clearLogs();
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogsList() {
    if (_filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _logs.isEmpty ? 'No logs available' : 'No logs match filters',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _buildLogEntry(log);
      },
    );
  }
  
  Widget _buildLogEntry(LogEntry log) {
    final levelColor = _getLevelColor(log.level);
    final timeFormat = DateFormat('HH:mm:ss.SSS');
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: levelColor,
            width: 3,
          ),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: const EdgeInsets.all(12),
        title: Row(
          children: [
            Text(
              timeFormat.format(log.timestamp),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.level.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: levelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '[${log.source.displayName}]',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '[${log.category.displayName}]',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            log.message,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        children: [
          if (log.metadata != null && log.metadata!.isNotEmpty) ...[
            Text(
              'Metadata:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              log.metadata.toString(),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (log.stackTrace != null) ...[
            const SizedBox(height: 8),
            Text(
              'Stack Trace:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.stackTrace!,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
  
  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.starting:
        return Colors.blue;
      case ServiceStatus.running:
        return Colors.green;
      case ServiceStatus.degraded:
        return Colors.orange;
      case ServiceStatus.failed:
        return Colors.red;
      case ServiceStatus.stopped:
        return Colors.grey;
    }
  }
  
  String _getStatusText(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.starting:
        return 'Starting';
      case ServiceStatus.running:
        return 'Running';
      case ServiceStatus.degraded:
        return 'Degraded';
      case ServiceStatus.failed:
        return 'Failed';
      case ServiceStatus.stopped:
        return 'Stopped';
    }
  }
  
  void _showGenericPicker<T>({
    required String allItemsText,
    required List<T> items,
    required String Function(T) getDisplayName,
    required T? currentValue,
    required void Function(T?) onSelectionChanged,
    Widget? Function(T)? buildLeading,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(allItemsText),
            onTap: () {
              setState(() {
                onSelectionChanged(null);
                _applyFilters();
              });
              Navigator.pop(context);
            },
          ),
          ...items.map((item) => ListTile(
            title: Text(getDisplayName(item)),
            leading: buildLeading?.call(item),
            onTap: () {
              setState(() {
                onSelectionChanged(item);
                _applyFilters();
              });
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  void _showLevelPicker() {
    _showGenericPicker<LogLevel>(
      allItemsText: 'All Levels',
      items: LogLevel.values,
      getDisplayName: (level) => level.displayName,
      currentValue: _selectedLevel,
      onSelectionChanged: (level) => _selectedLevel = level,
      buildLeading: (level) => CircleAvatar(
        backgroundColor: _getLevelColor(level),
        radius: 8,
      ),
    );
  }
  
  void _showSourcePicker() {
    _showGenericPicker<LogSource>(
      allItemsText: 'All Sources',
      items: LogSource.values,
      getDisplayName: (source) => source.displayName,
      currentValue: _selectedSource,
      onSelectionChanged: (source) => _selectedSource = source,
    );
  }
  
  void _showCategoryPicker() {
    _showGenericPicker<LogCategory>(
      allItemsText: 'All Categories',
      items: LogCategory.values,
      getDisplayName: (category) => category.displayName,
      currentValue: _selectedCategory,
      onSelectionChanged: (category) => _selectedCategory = category,
    );
  }
  
  Future<bool?> _showClearConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}