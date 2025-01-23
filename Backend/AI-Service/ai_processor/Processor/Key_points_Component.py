from abc import ABC, abstractmethod
from django.conf import settings
import requests
import os


api_key = settings.DEEPGRAM_API_KEY
openai_api_key = settings.OPENAI_API_KEY

class KeyPointsStrategy(ABC):
    @abstractmethod
    def extract_key_points(self, summary):
        print("step06: extract key points strategy")
        pass

class AdvancedKeyPoints(KeyPointsStrategy):
    def extract_key_points(self, summary):
        print("step06: advanced key points using open ai")
        prompt = f"""
        i will provide you a summary of a meeting ,extract the summarized key points from it.
        and format it in a list of key points. separate each key point with a // mark.
        the summary is:
        {summary}
        """
        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {openai_api_key}"
        }
        
        data = {
            "model": "gpt-4o-mini",
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.7,
        }
        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 200:
            result = response.json()
            message_content = result['choices'][0]['message']['content']

        else:
            print(f"Request failed with status code {response.status_code}: {response.text}")
        return message_content
        
