import requests
import os
from urllib.parse import urlparse

def fetch_audio_from_url(audio_url):

    # Get file extension from URL
    parsed_url = urlparse(audio_url)
    file_extension = os.path.splitext(parsed_url.path)[1].lower()
    
    # Check if file format is supported
    supported_formats = ['.wav', '.mp3', '.m4a', '.opus']
    if file_extension not in supported_formats:
        raise Exception(f"Unsupported file format. Supported formats are: {', '.join(supported_formats)}")

    # Download the file
    try:
        # Headers optimized for S3 pre-signed URLs
        headers = {
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br'
        }
        
        response = requests.get(
            audio_url,
            headers=headers,
            stream=True,
            timeout=30  # Add timeout to prevent hanging
        )
        response.raise_for_status()
        
        return response.content, file_extension.lstrip('.')
        
    except requests.exceptions.RequestException as e:
        raise Exception(f"Failed to fetch audio file from URL: {audio_url}. Error: {str(e)}")
