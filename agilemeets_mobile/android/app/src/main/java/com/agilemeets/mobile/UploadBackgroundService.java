package com.agilemeets.mobile;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import androidx.core.app.NotificationCompat;
import android.util.Log;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class UploadBackgroundService extends Service {
    private static final String CHANNEL_ID = "upload_service";
    private static final int NOTIFICATION_ID = 2;
    private String meetingId;
    private String filePath;
    private double progress;
    private boolean isPaused = false;
    private NotificationManager notificationManager;
    private ExecutorService executorService;
    private FlutterEngine flutterEngine;
    private MethodChannel methodChannel;
    private boolean isUploading = false;

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        notificationManager = getSystemService(NotificationManager.class);
        executorService = Executors.newSingleThreadExecutor();
        createNotificationChannel();
        setupFlutterEngine();
    }

    private void setupFlutterEngine() {
        flutterEngine = new FlutterEngine(this);
        flutterEngine.getDartExecutor().executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        );
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), 
            "com.agilemeets.mobile/upload_service");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            // Handle new upload request
            if (intent.hasExtra("meetingId") && intent.hasExtra("filePath")) {
                meetingId = intent.getStringExtra("meetingId");
                filePath = intent.getStringExtra("filePath");
                progress = 0;
                isPaused = false;
                startForeground(NOTIFICATION_ID, createNotification());
                Log.d("UploadService", "Started upload service for meeting: " + meetingId);
            }
            // Handle progress update from Flutter
            else if (intent.hasExtra("progress")) {
                // Convert from integer percentage to double
                int intProgress = intent.getIntExtra("progress", 0);
                progress = intProgress / 100.0;
                updateNotification();
                Log.d("UploadService", "Updated progress: " + progress);
            }
            // Handle pause/resume
            else if (intent.hasExtra("action")) {
                String action = intent.getStringExtra("action");
                if ("pause".equals(action)) {
                    isPaused = true;
                    updateNotification();
                    Log.d("UploadService", "Upload paused");
                } else if ("resume".equals(action)) {
                    isPaused = false;
                    updateNotification();
                    Log.d("UploadService", "Upload resumed");
                }
            }
        }
        return START_STICKY;
    }

    // private void startUpload() {
    //     if (isUploading || isPaused) return;

    //     isUploading = true;
    //     executorService.execute(() -> {
    //         FileInputStream inputStream = null;
    //         try {
    //             File file = new File(filePath);
    //             if (!file.exists()) {
    //                 throw new IOException("File not found: " + filePath);
    //             }

    //             long fileSize = file.length();
    //             inputStream = new FileInputStream(file);
    //             byte[] buffer = new byte[8192];
    //             long totalBytesRead = 0;
    //             int bytesRead;

    //             while ((bytesRead = inputStream.read(buffer)) != -1 && !isPaused && isUploading) {
    //                 try {
    //                     totalBytesRead += bytesRead;
    //                     progress = Math.min(1.0, (double) totalBytesRead / fileSize);
                        
    //                     // Only update progress if still uploading
    //                     if (isUploading && !isPaused) {
    //                         // Update progress on main thread
    //                         final double currentProgress = progress;
    //                         getMainExecutor().execute(() -> {
    //                             if (isUploading && !isPaused) {
    //                                 updateNotification();
    //                                 methodChannel.invokeMethod("onUploadProgress", currentProgress);
    //                             }
    //                         });
    //                     }

    //                     // Simulate network delay - reduced for smoother updates
    //                     if (isUploading && !isPaused) {
    //                         Thread.sleep(50);
    //                     }
    //                 } catch (InterruptedException e) {
    //                     // Handle interruption gracefully
    //                     Log.d("UploadService", "Upload interrupted");
    //                     break;
    //                 }
    //             }

    //             // Only complete if not interrupted or paused
    //             if (!isPaused && isUploading) {
    //                 getMainExecutor().execute(() -> {
    //                     methodChannel.invokeMethod("onUploadComplete", null);
    //                     stopSelf();
    //                 });
    //             }
    //         } catch (Exception e) {
    //             Log.e("UploadService", "Error during upload", e);
    //             getMainExecutor().execute(() -> {
    //                 methodChannel.invokeMethod("onUploadError", e.getMessage());
    //                 stopSelf();
    //             });
    //         } finally {
    //             isUploading = false;
    //             if (inputStream != null) {
    //                 try {
    //                     inputStream.close();
    //                 } catch (IOException e) {
    //                     Log.e("UploadService", "Error closing input stream", e);
    //                 }
    //             }
    //         }
    //     });
    // }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Upload Service",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Used for background upload service");
            channel.setSound(null, null);
            channel.enableVibration(false);
            channel.setShowBadge(false);
            channel.setLockscreenVisibility(Notification.VISIBILITY_PRIVATE);
            
            notificationManager.createNotificationChannel(channel);
            Log.d("UploadService", "Created notification channel");
        }
    }

    private Notification createNotification() {
        Intent launchIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        if (launchIntent != null && meetingId != null) {
            launchIntent.putExtra("meetingId", meetingId);
            launchIntent.putExtra("action", "openUpload");
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        }

        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 
            0, 
            launchIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        // Calculate percentage for notification (0-100)
        int progressPercent = Math.min(100, Math.max(0, (int)(progress * 100)));

        String contentText = isPaused 
            ? "Upload paused - Tap to resume" 
            : progress > 0 
                ? String.format("Progress: %d%%", progressPercent)
                : "Preparing upload...";

        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(isPaused ? "Upload Paused" : "Uploading Recording")
            .setContentText(contentText)
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false)
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setProgress(100, progressPercent, progress == 0)
            .setStyle(new NotificationCompat.DecoratedCustomViewStyle())
            .setSubText(isPaused ? "Paused" : "Uploading");

        return builder.build();
    }

    private void updateNotification() {
        notificationManager.notify(NOTIFICATION_ID, createNotification());
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d("UploadService", "Service being destroyed");
        
        // Stop foreground service and cancel upload
        stopForeground(true);
        isUploading = false;
        isPaused = true;
        
        // Shutdown executor service gracefully
        if (executorService != null && !executorService.isShutdown()) {
            try {
                // Attempt graceful shutdown first
                executorService.shutdown();
                if (!executorService.awaitTermination(2, TimeUnit.SECONDS)) {
                    // Force shutdown if graceful shutdown fails
                    executorService.shutdownNow();
                }
            } catch (InterruptedException e) {
                Log.e("UploadService", "Error shutting down executor service", e);
                executorService.shutdownNow();
            }
        }
        
        // Clean up Flutter engine
        if (flutterEngine != null) {
            try {
                // Notify Flutter about service destruction
                if (methodChannel != null) {
                    methodChannel.invokeMethod("onServiceDestroyed", null);
                }
                flutterEngine.destroy();
            } catch (Exception e) {
                Log.e("UploadService", "Error destroying Flutter engine", e);
            }
        }
        
        // Clear notification
        if (notificationManager != null) {
            notificationManager.cancel(NOTIFICATION_ID);
        }
        
        Log.d("UploadService", "Upload service destroyed successfully");
    }
} 