import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/recording_metadata.dart';
import 'dart:developer' as dev;

class RecordingStorageService {
  static const String _boxName = 'recordings';
  late Box<RecordingMetadata> _box;
  bool _isInitialized = false;

  /// Initialize the storage service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      dev.log('Initializing RecordingStorageService', name: 'RecordingStorageService');
      
      // Note: Hive.initFlutter() and adapter registration is now handled in main.dart
      
      try {
        // Try to open the box first
        _box = await Hive.openBox<RecordingMetadata>(_boxName);
      } catch (e) {
        dev.log('Error opening box, attempting recovery: $e', name: 'RecordingStorageService');
        // Only delete the box if we couldn't open it (corruption)
        try {
          await Hive.deleteBoxFromDisk(_boxName);
          _box = await Hive.openBox<RecordingMetadata>(_boxName);
        } catch (e) {
          dev.log('Error recovering box: $e', name: 'RecordingStorageService');
          rethrow;
        }
      }
      
      _isInitialized = true;
      dev.log('Hive box opened: $_boxName with ${_box.length} recordings', name: 'RecordingStorageService');
    } catch (e) {
      dev.log('Error initializing storage: $e', name: 'RecordingStorageService', error: e);
      rethrow;
    }
  }

  /// Save a new recording metadata
  Future<void> saveRecording(RecordingMetadata metadata) async {
    if (!_isInitialized) await init();
    
    dev.log('Saving recording: ${metadata.id}', name: 'RecordingStorageService');
    await _box.put(metadata.id, metadata);
    dev.log('Recording saved successfully', name: 'RecordingStorageService');
  }

  /// Get all pending recordings (not completed or failed)
  Future<List<RecordingMetadata>> getPendingRecordings() async {
    if (!_isInitialized) await init();
    
    dev.log('Getting pending recordings', name: 'RecordingStorageService');
    final recordings = _box.values
        .where((r) => r.status != RecordingUploadStatus.completed)
        .toList();
    dev.log('Found ${recordings.length} pending recordings', name: 'RecordingStorageService');
    return recordings;
  }

  /// Get all recordings for a specific meeting
  Future<List<RecordingMetadata>> getMeetingRecordings(String meetingId) async {
    if (!_isInitialized) await init();
    
    dev.log('Getting recordings for meeting: $meetingId', name: 'RecordingStorageService');
    final recordings = _box.values
        .where((r) => r.meetingId == meetingId)
        .toList();
    dev.log('Found ${recordings.length} recordings for meeting', name: 'RecordingStorageService');
    return recordings;
  }

  /// Update an existing recording metadata
  Future<void> updateRecording(RecordingMetadata metadata) async {
    if (!_isInitialized) await init();
    
    dev.log('Updating recording: ${metadata.id}', name: 'RecordingStorageService');
    await _box.put(metadata.id, metadata);
    dev.log('Recording updated successfully', name: 'RecordingStorageService');
  }

  /// Delete a recording and its file
  Future<void> deleteRecording(String meetingId) async {
    if (!_isInitialized) await init();
    
    dev.log('Deleting recording: $meetingId', name: 'RecordingStorageService');
    final recording = _box.values.firstWhere((r) => r.meetingId == meetingId);
    try {
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
        dev.log('Recording file deleted', name: 'RecordingStorageService');
      }
    } catch (e) {
      dev.log('Error deleting recording file: $e', name: 'RecordingStorageService', error: e);
    }
    await _box.delete(recording.id);
    dev.log('Recording metadata deleted', name: 'RecordingStorageService');
  }

  /// Clean up expired recordings
  Future<void> cleanupExpiredRecordings() async {
    if (!_isInitialized) await init();
    
    final expired = _box.values.where((r) => r.isExpired).toList();
    for (final recording in expired) {
      try {
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        await _box.delete(recording.id);
      } catch (e) {
        debugPrint('Error cleaning up recording: $e');
      }
    }
  }

  /// Get the recordings directory path
  Future<String> getRecordingsDirectory() async {
    dev.log('Getting recordings directory', name: 'RecordingStorageService');
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
      dev.log('Created recordings directory', name: 'RecordingStorageService');
    }
    dev.log('Recordings directory: ${recordingsDir.path}', name: 'RecordingStorageService');
    return recordingsDir.path;
  }

  /// Move a recording file from temporary to permanent storage
  Future<String> moveToStorage(String tempPath, String meetingId) async {
    dev.log('Moving recording to storage: $tempPath', name: 'RecordingStorageService');
    final recordingsDir = await getRecordingsDirectory();
    final fileName = 'meeting_${meetingId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final permanentPath = '$recordingsDir/$fileName';
    
    await File(tempPath).copy(permanentPath);
    await File(tempPath).delete();
    
    dev.log('Recording moved to: $permanentPath', name: 'RecordingStorageService');
    return permanentPath;
  }

  /// Close the box and cleanup
  Future<void> dispose() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }
} 