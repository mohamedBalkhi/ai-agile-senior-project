from django.urls import path
from ai_processor.Views.Status import StatusAPIView
from ai_processor.Views.Report import ReportAPIView
from ai_processor.Views.Audios import (
    SubmitAudioAPIView
)

urlpatterns = [
    path('submit_audio/', SubmitAudioAPIView.as_view(), name='submit_audio'),
    path('status/<uuid:audio_token>/', StatusAPIView.as_view(), name='audio-status'),
    path('report/<uuid:audio_token>/', ReportAPIView.as_view(), name='audio-report'),
]


