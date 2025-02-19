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

public class AudioRecordingService extends Service {
    private static final String CHANNEL_ID = "audio_recording_service";
    private static final int NOTIFICATION_ID = 1;
    private String meetingId;

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            meetingId = intent.getStringExtra("meetingId");
        }
        createNotificationChannel();
        startForeground(NOTIFICATION_ID, createNotification());
        return START_STICKY;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Audio Recording Service",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Used for audio recording background service");
            channel.setSound(null, null);
            channel.enableVibration(false);
            channel.setShowBadge(false);
            
            channel.setLockscreenVisibility(Notification.VISIBILITY_PRIVATE);
            
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);
        }
    }

    private Notification createNotification() {
        Intent launchIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        if (launchIntent != null && meetingId != null) {
            launchIntent.putExtra("meetingId", meetingId);
            launchIntent.putExtra("action", "openRecording");
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        }

        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 
            0, 
            launchIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Recording in Progress")
            .setContentText("Recording in progress...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false)
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setUsesChronometer(true)
            .setWhen(System.currentTimeMillis())
            .setShowWhen(true)
            .setStyle(new NotificationCompat.DecoratedCustomViewStyle())
            .setSubText("Recording");

        return builder.build();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopForeground(true);
    }
} 