#MongoDB_models

from djongo import models
import uuid  


class AudioProcessing(models.Model):
    audio_token = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)  
    audio_url = models.URLField(blank=True, null=True)
    transcript = models.TextField(blank=True, null=True)
    summarization = models.TextField(blank=True, null=True)
    processing_status = models.CharField(
        max_length=50,
        choices=[
            ('ON_QUEUE', 'On Queue'),
            ('STT_PROCESSED', 'STT Processed'),
            ('SUMMARY_PROCESSED', 'Summary Processed'),
            ('KEY_POINTS_PROCESSED', 'Key Points Processed'),
            ('COMPLETED', 'Completed'),
            ('FAILED', 'Failed')
        ],
        default='ON_QUEUE'
    )
    key_points = models.JSONField(blank=True, null=True, default=list)  # Stores array of key points
    main_language = models.CharField(max_length=10, default='en', null=True)  # ISO language code
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    user_plan = models.CharField(max_length=50, default='base', null=True)

    class Meta:
        db_table = 'audio_processing'

    def __str__(self):
        return f"Audio {self.audio_token} - {self.processing_status}"