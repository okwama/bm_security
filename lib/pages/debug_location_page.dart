import 'package:flutter/material.dart';
import 'package:bm_security/services/location_service.dart';
import 'dart:convert';

class DebugLocationPage extends StatefulWidget {
  const DebugLocationPage({Key? key}) : super(key: key);

  @override
  State<DebugLocationPage> createState() => _DebugLocationPageState();
}

class _DebugLocationPageState extends State<DebugLocationPage> {
  final LocationService _locationService = LocationService();
  final TextEditingController _requestIdController = TextEditingController();
  Map<String, dynamic>? _debugResults;
  bool _isLoading = false;
  String _logs = '';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  void _addLog(String message) {
    setState(() {
      _logs =
          '$_logs\n${DateTime.now().toString().substring(11, 19)} - $message';
    });
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final debugInfo = await _locationService.debugLocationTracking();
      setState(() {
        _debugResults = debugInfo;
      });
    } catch (e) {
      _addLog('Error loading debug info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startTracking() async {
    if (_requestIdController.text.isEmpty) {
      _addLog('Please enter a request ID');
      return;
    }

    _addLog(
        'Starting location tracking for request: ${_requestIdController.text}');

    try {
      final result = await _locationService.startTracking(
        _requestIdController.text,
        myStatus: 2,
      );
      _addLog('Start tracking result: $result');
      _loadDebugInfo(); // Refresh debug info
    } catch (e) {
      _addLog('Error starting tracking: $e');
    }
  }

  Future<void> _stopTracking() async {
    _addLog('Stopping location tracking');

    try {
      await _locationService.stopTracking();
      _addLog('Location tracking stopped');
      _loadDebugInfo(); // Refresh debug info
    } catch (e) {
      _addLog('Error stopping tracking: $e');
    }
  }

  Future<void> _testLocationUpdate() async {
    if (_requestIdController.text.isEmpty) {
      _addLog('Please enter a request ID');
      return;
    }

    _addLog(
        'Testing location update for request: ${_requestIdController.text}');

    try {
      await _locationService.testLocationUpdate(_requestIdController.text);
      _addLog('Test location update completed');
    } catch (e) {
      _addLog('Error testing location update: $e');
    }
  }

  Future<void> _startAutoBackup() async {
    _addLog('Starting automatic backup system...');

    try {
      await _locationService.startAutoBackupSystem();
      _addLog('Auto backup system started');
      _loadDebugInfo(); // Refresh debug info
    } catch (e) {
      _addLog('Error starting auto backup: $e');
    }
  }

  Future<void> _stopAutoBackup() async {
    _addLog('Stopping automatic backup system...');

    try {
      await _locationService.stopAutoBackupSystem();
      _addLog('Auto backup system stopped');
      _loadDebugInfo(); // Refresh debug info
    } catch (e) {
      _addLog('Error stopping auto backup: $e');
    }
  }

  Future<void> _checkUntrackedRequests() async {
    _addLog('Checking for untracked requests...');

    try {
      final untrackedRequests =
          await _locationService.checkAndStartUntrackedRequests();

      if (untrackedRequests.isEmpty) {
        _addLog('No untracked requests found');
      } else {
        _addLog('Found ${untrackedRequests.length} untracked requests:');
        for (final request in untrackedRequests) {
          _addLog(
              '- Request ${request['id']}: ${request['userName']} (Status: ${request['myStatus']})');
        }
      }

      _loadDebugInfo(); // Refresh debug info
    } catch (e) {
      _addLog('Error checking untracked requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Location Tracking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request ID Input
            TextField(
              controller: _requestIdController,
              decoration: const InputDecoration(
                labelText: 'Request ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startTracking,
                    child: const Text('Start Tracking'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _stopTracking,
                    child: const Text('Stop Tracking'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testLocationUpdate,
                    child: const Text('Test Location Update'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loadDebugInfo,
                    child: const Text('Refresh Debug'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Auto Backup System Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startAutoBackup,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Start Auto Backup'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _stopAutoBackup,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Stop Auto Backup'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Check Untracked Requests
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkUntrackedRequests,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Check Untracked Requests'),
              ),
            ),

            const SizedBox(height: 24),

            // Debug Results
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_debugResults != null) ...[
              const Text(
                'Debug Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(_debugResults),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Logs section
            const Text(
              'Activity Logs:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _logs.isEmpty ? 'No logs yet...' : _logs,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _requestIdController.dispose();
    super.dispose();
  }
}
