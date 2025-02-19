package com.agilemeets.mobile;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Intent;
import android.os.Build;
import android.content.pm.PackageManager;
import android.Manifest;
import androidx.core.content.ContextCompat;
import android.util.Log;
import androidx.annotation.NonNull;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.agilemeets.mobile/audio_recording_service";
    private static final String UPLOAD_CHANNEL = "com.agilemeets.mobile/upload_service";
    private static final String NAVIGATION_CHANNEL = "com.agilemeets.mobile/navigation";
    private Intent audioServiceIntent;
    private Intent uploadServiceIntent;
    private MethodChannel navigationChannel;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    switch (call.method) {
                        case "startAudioService":
                            String meetingId = call.argument("meetingId");
                            startAudioRecordingService(meetingId, result);
                            break;
                        case "stopAudioService":
                            stopAudioRecordingService(result);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                }
            );

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), UPLOAD_CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    switch (call.method) {
                        case "startUploadService":
                            String meetingId = call.argument("meetingId");
                            String filePath = call.argument("filePath");
                            startUploadService(meetingId, filePath, result);
                            break;
                        case "stopUploadService":
                            stopUploadService(result);
                            break;
                        case "updateUploadProgress":
                            if (call.argument("progress") != null) {
                            Object progressObj = call.argument("progress");
                            int progress;
                            
                            if (progressObj instanceof Integer) {
                                progress = (Integer) progressObj;
                            } else if (progressObj instanceof Double) {
                                progress = ((Double) progressObj).intValue();
                            } else if (progressObj instanceof Long) {
                                progress = ((Long) progressObj).intValue();
                            } else {
                                throw new IllegalArgumentException("Progress must be a number");
                            }
                                updateUploadProgress(progress, result);
                            }
                            break;
                        case "pauseUpload":
                            pauseUpload(result);
                            break;
                        case "resumeUpload":
                            resumeUpload(result);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                }
            );

        navigationChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), NAVIGATION_CHANNEL);
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        handleIntent(getIntent());
    }

    private void handleIntent(Intent intent) {
        if (intent != null && intent.hasExtra("meetingId") && intent.hasExtra("action")) {
            String meetingId = intent.getStringExtra("meetingId");
            String action = intent.getStringExtra("action");
            
            if ("openRecording".equals(action)) {
                navigationChannel.invokeMethod("openRecordingScreen", meetingId);
            }
        }
    }

    private boolean checkAudioPermissions() {
        boolean hasRecordPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) 
            == PackageManager.PERMISSION_GRANTED;
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            boolean hasForegroundMicPermission = ContextCompat.checkSelfPermission(this, 
                "android.permission.FOREGROUND_SERVICE_MICROPHONE") == PackageManager.PERMISSION_GRANTED;
            return hasRecordPermission && hasForegroundMicPermission;
        }
        
        return hasRecordPermission;
    }

    private void startAudioRecordingService(String meetingId, MethodChannel.Result result) {
        try {
            if (!checkAudioPermissions()) {
                result.error("PERMISSION_DENIED", 
                    "Required permissions are not granted. Please check RECORD_AUDIO and FOREGROUND_SERVICE_MICROPHONE permissions.", 
                    null);
                return;
            }

            audioServiceIntent = new Intent(this, AudioRecordingService.class);
            if (meetingId != null) {
                audioServiceIntent.putExtra("meetingId", meetingId);
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(audioServiceIntent);
            } else {
                startService(audioServiceIntent);
            }
            result.success(true);
        } catch (Exception e) {
            Log.e("MainActivity", "Failed to start audio service", e);
            result.error("SERVICE_START_FAILED", e.getMessage(), null);
        }
    }

    private void stopAudioRecordingService(MethodChannel.Result result) {
        try {
            if (audioServiceIntent != null) {
                stopService(audioServiceIntent);
                audioServiceIntent = null;
            }
            result.success(true);
        } catch (Exception e) {
            result.error("SERVICE_STOP_FAILED", e.getMessage(), null);
        }
    }

    private void startUploadService(String meetingId, String filePath, MethodChannel.Result result) {
        try {
            uploadServiceIntent = new Intent(this, UploadBackgroundService.class);
            uploadServiceIntent.putExtra("meetingId", meetingId);
            uploadServiceIntent.putExtra("filePath", filePath);
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(uploadServiceIntent);
            } else {
                startService(uploadServiceIntent);
            }
            
            result.success(true);
        } catch (Exception e) {
            Log.e("MainActivity", "Error starting upload service", e);
            result.error("START_UPLOAD_ERROR", e.getMessage(), null);
        }
    }

    private void stopUploadService(MethodChannel.Result result) {
        try {
            if (uploadServiceIntent != null) {
                stopService(uploadServiceIntent);
                uploadServiceIntent = null;
            }
            result.success(true);
        } catch (Exception e) {
            Log.e("MainActivity", "Error stopping upload service", e);
            result.error("STOP_UPLOAD_ERROR", e.getMessage(), null);
        }
    }

    private void updateUploadProgress(int progress, MethodChannel.Result result) {
        try {
            if (uploadServiceIntent != null) {
                Intent updateIntent = new Intent(this, UploadBackgroundService.class);
                updateIntent.putExtra("progress", progress);
                startService(updateIntent);
            }
            result.success(true);
        } catch (Exception e) {
            Log.e("MainActivity", "Error updating upload progress", e);
            result.error("UPDATE_PROGRESS_ERROR", e.getMessage(), null);
        }
    }

    private void pauseUpload(MethodChannel.Result result) {
        try {
            if (uploadServiceIntent != null) {
                Intent pauseIntent = new Intent(this, UploadBackgroundService.class);
                pauseIntent.putExtra("action", "pause");
                startService(pauseIntent);
            }
            result.success(true);
        } catch (Exception e) {
            Log.e("MainActivity", "Error pausing upload", e);
            result.error("PAUSE_UPLOAD_ERROR", e.getMessage(), null);
        }
    }

    private void resumeUpload(MethodChannel.Result result) {
        try {
            if (uploadServiceIntent != null) {
                Intent resumeIntent = new Intent(this, UploadBackgroundService.class);
                resumeIntent.putExtra("action", "resume");
                startService(resumeIntent);
            }
            result.success(true);
        } catch (Exception e) {
            Log.e("MainActivity", "Error resuming upload", e);
            result.error("RESUME_UPLOAD_ERROR", e.getMessage(), null);
        }
    }
} 