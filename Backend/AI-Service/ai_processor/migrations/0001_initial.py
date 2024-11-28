# Generated by Django 5.1.3 on 2024-11-28 07:22

import djongo.models.fields
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='AudioProcessing',
            fields=[
                ('audio_token', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('audio_url', models.URLField(blank=True, null=True)),
                ('transcript', models.TextField(blank=True, null=True)),
                ('summarization', models.TextField(blank=True, null=True)),
                ('processing_status', models.CharField(choices=[('ON_QUEUE', 'On Queue'), ('STT_PROCESSED', 'STT Processed'), ('SUMMARY_PROCESSED', 'Summary Processed'), ('KEY_POINTS_PROCESSED', 'Key Points Processed'), ('COMPLETED', 'Completed'), ('FAILED', 'Failed')], default='ON_QUEUE', max_length=50)),
                ('key_points', djongo.models.fields.JSONField(blank=True, default=list, null=True)),
                ('main_language', models.CharField(default='en', max_length=10, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user_plan', models.CharField(default='base', max_length=50, null=True)),
            ],
            options={
                'db_table': 'audio_processing',
            },
        ),
    ]
