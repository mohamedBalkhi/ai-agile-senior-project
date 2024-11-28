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
        DEEPGRAM_API_KEY = settings.DEEPGRAM_API_KEY
        dg_client = Deepgram(DEEPGRAM_API_KEY)

        async def transcribe_audio(file_path):
            """Transcribe an audio file using Deepgram Nova-2."""
            with open(file_path, 'rb') as audio:
                source = {'buffer': audio, 'mimetype': 'audio/wav'}
                options = {'model': 'nova-2', 'punctuate': True, 'language': 'en-US'}
                response = await dg_client.transcription.prerecorded(source, options)
                print(response)
                return response.results.channels[0].alternatives[0].transcript

class ArabicSpeechToText(SpeechToTextStrategy):
    def convert_speech_to_text(self, file_url):
        print("step02: arabic speech to text")
        return f"Arabic transcript of {file_url}"
