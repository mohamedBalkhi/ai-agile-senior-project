import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

class PendingRecording {
  final String meetingId;
  final String filePath;
  final DateTime recordedAt;

  PendingRecording({
    required this.meetingId,
    required this.filePath,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'meetingId': meetingId,
        'filePath': filePath,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory PendingRecording.fromJson(Map<String, dynamic> json) {
    return PendingRecording(
      meetingId: json['meetingId'],
      filePath: json['filePath'],
      recordedAt: DateTime.parse(json['recordedAt']),
    );
  }
}

class PendingRecordingsStorage {
  static const String _key = 'pending_recordings';

  static Future<void> savePendingRecording(PendingRecording recording) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordings = await getPendingRecordings();
      recordings.add(recording);
      
      await prefs.setString(
        _key,
        jsonEncode(recordings.map((r) => r.toJson()).toList()),
      );
      
      developer.log(
        'Saved pending recording for meeting ${recording.meetingId}',
        name: 'PendingRecordingsStorage',
      );
    } catch (e) {
      developer.log(
        'Error saving pending recording: $e',
        name: 'PendingRecordingsStorage',
        error: e,
      );
    }
  }

  static Future<List<PendingRecording>> getPendingRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recordingsJson = prefs.getString(_key);
      
      if (recordingsJson == null) return [];
      
      final List<dynamic> recordingsList = jsonDecode(recordingsJson);
      return recordingsList
          .map((json) => PendingRecording.fromJson(json))
          .toList();
    } catch (e) {
      developer.log(
        'Error getting pending recordings: $e',
        name: 'PendingRecordingsStorage',
        error: e,
      );
      return [];
    }
  }

  static Future<PendingRecording?> getPendingRecordingForMeeting(String meetingId) async {
    try {
      final recordings = await getPendingRecordings();
      return recordings.firstWhere(
        (recording) => recording.meetingId == meetingId,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> removePendingRecording(String meetingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordings = await getPendingRecordings();
      recordings.removeWhere((recording) => recording.meetingId == meetingId);
      
      await prefs.setString(
        _key,
        jsonEncode(recordings.map((r) => r.toJson()).toList()),
      );
      
      developer.log(
        'Removed pending recording for meeting $meetingId',
        name: 'PendingRecordingsStorage',
      );
    } catch (e) {
      developer.log(
        'Error removing pending recording: $e',
        name: 'PendingRecordingsStorage',
        error: e,
      );
    }
  }
}
