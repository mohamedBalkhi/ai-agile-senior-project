from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('ai_processor/', include('ai_processor.urls')),
]
