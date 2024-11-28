from pathlib import Path
import os
from dotenv import load_dotenv
from .migration_skipping import DisableMigrations

# Load environment variables
BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(os.path.join(BASE_DIR, '.env'))

# Environment Variables
API_KEYS_SERVICE = os.getenv("API_KEYS_SERVICE")
SECRET_KEY = os.getenv("SECRET_KEY", "default-secret-key")  # Provide fallback for SECRET_KEY
DEEPGRAM_API_KEY = os.getenv("DEEPGRAM_API_KEY")


# Create audios folder if not exists
AUDIOS_FOLDER = os.path.join(BASE_DIR, 'audios')
os.makedirs(AUDIOS_FOLDER, exist_ok=True)

# Security Settings
DEBUG = True  # Set to False in production
ALLOWED_HOSTS = []

# Installed Applications
INSTALLED_APPS = [
    'django.contrib.contenttypes',  # Required for Django ORM
    'django.contrib.staticfiles',   # For static files (if needed)
    'ai_processor',          
    'django_extensions',
    'rest_framework',      
]
MIGRATION_MODULES = DisableMigrations()


# Middleware
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.common.CommonMiddleware',
]

# Rest Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'ai_processor.authentication.APIKeyAuthentication',
    ],
}

# URL and WSGI Config
ROOT_URLCONF = 'ai_service.urls'
WSGI_APPLICATION = 'ai_service.wsgi.application'

# MongoDB Database Configuration
DATABASES = {
    'default': {
        'ENGINE': 'djongo',
        'NAME': 'AgileMeets-DB',
        'CLIENT': {
            'host': 'mongodb://localhost:27017',
            'port': 27017,
        },
    }
}

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static Files
STATIC_URL = 'static/'

# Default Primary Key Field
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
