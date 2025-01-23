from abc import ABC, abstractmethod
import os
from django.conf import settings
from openai import OpenAI
import os
from deepgram import (
    DeepgramClient,
    PrerecordedOptions,
    FileSource,
)
import requests


api_key = settings.DEEPGRAM_API_KEY
class SpeechToTextStrategy(ABC):
    @abstractmethod
    def convert_speech_to_text(self, file_path):
        pass


class EnglishSpeechToText(SpeechToTextStrategy):
    def convert_speech_to_text(self, file_path):
        url = "https://api.deepgram.com/v1/listen"

        headers = {
            "Authorization": f"Token {api_key}",
            "Content-Type": "audio/*"
        }   

        # Get the audio file
        with open(file_path, "rb") as audio_file:
            # Make the HTTP request
            response = requests.post(url, headers=headers, data=audio_file)
            transcript = response.json().get("results", {}).get("channels", [{}])[0].get("alternatives", [{}])[0].get("transcript", "")

        print(transcript)
        return transcript

        # print("step02: english speech to text -  nova02")
        # try:
        #     deepgram = DeepgramClient(api_key)
        #     with open(file_path, "rb") as file:
        #         buffer_data = file.read()
        #     payload: FileSource = {
        #         "buffer": buffer_data,
        #         "mimetype": "audio/m4a"  
        #     }
        #     options = PrerecordedOptions(
        #         model="nova-2",
        #         smart_format=True,
        #         language="en", 
        #         tier="enhanced"  
        #     )
        #     response = deepgram.listen.rest.v("1").transcribe_file(payload, options)

        #     print(response.to_json(indent=4))
        
        #     # Extract the transcript from the response
        #     if response and response.get("results"):
        #         transcript = response["results"]["channels"][0]["alternatives"][0]["transcript"]
        #         return transcript
        #     else:
        #         print("No transcription results found in the response")
        #         return "Error: Failed to transcribe audio"
        
        # except Exception as e:
        #     print(f"Exception in English STT: {e}")
        #     return "Error: Failed to transcribe audio"


class ArabicSpeechToText(SpeechToTextStrategy):

    def convert_speech_to_text(self, file_path):
        print("arabic speech to text - whisper large")
        client = OpenAI()
        with open(file_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file
            )
            print(transcription.text)
        return transcription.text
    
