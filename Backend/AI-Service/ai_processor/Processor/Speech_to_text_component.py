from abc import ABC, abstractmethod
from deepgram import Deepgram
import os
from django.conf import settings

class SpeechToTextStrategy(ABC):
    @abstractmethod
    def convert_speech_to_text(self, file_url):
        print("step02: speech to text strategy")
        pass


class EnglishSpeechToText(SpeechToTextStrategy):
    def convert_speech_to_text(self, file_url):
        print("step02: english speech to text")
        DEEPGRAM_API_KEY = "e668d1b00c5b6b44ccdfb02f56dd1776c86cd65b"
        dg_client = Deepgram(DEEPGRAM_API_KEY)
        # Call the transcribe_audio function directly
        transcript = self._transcribe_audio(file_url, dg_client)
        return transcript
        
    def _transcribe_audio(self, file_path, dg_client):
        """Transcribe an audio file using Deepgram Nova-2."""
        print("use deep gram nova-2")
        with open(file_path, 'rb') as audio:
            source = {'buffer': audio, 'mimetype': 'audio/wav'}
            options = {'model': 'nova-2', 'punctuate': True, 'language': 'en-US'}

            print ("file opened successfully")
            # Use sync version of the transcription call
            response = dg_client.transcription.sync_prerecorded(source, options)
            return response['results']['channels'][0]['alternatives'][0]['transcript']

class ArabicSpeechToText(SpeechToTextStrategy):

    def convert_speech_to_text(self, file_url):
        print("step02: arabic speech to text")
        return f"Arabic transcript of {file_url}"
