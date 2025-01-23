import requests
import os
from django.conf import settings
from urllib.parse import urlparse
import uuid

def download_audio_to_storage(url, audio_id):
    """
    Downloads audio from URL and saves it to the configured AUDIOS_FOLDER
    
    Args:
        url (str): The URL of the audio file
        audio_id (str): Unique identifier for the audio
        
    Returns:
        tuple: (file_path, file_format)
    """
    try:
        # Extract file extension from URL or default to .mp3
        parsed_url = urlparse(url)
        path = parsed_url.path
        extension = os.path.splitext(path)[1] or '.mp3'
        
        # Create file path in AUDIOS_FOLDER
        file_name = f"{audio_id}{extension}"
        file_path = os.path.join(settings.AUDIOS_FOLDER, file_name)
        
        # Download the file with streaming to handle large files
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        # Write the file in chunks
        with open(file_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        return file_path, extension.lstrip('.')
        
    except requests.exceptions.RequestException as e:
        raise Exception(f"Failed to download audio: {str(e)}")
    except Exception as e:
        raise Exception(f"Error processing audio download: {str(e)}")
    


def cleanup_audio_file(file_path):

    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"Cleaned up file: {file_path}")
    except Exception as e:
        print(f"Warning: Failed to cleanup file {file_path}: {str(e)}")