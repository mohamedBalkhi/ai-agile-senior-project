from abc import ABC, abstractmethod
from django.conf import settings
import requests
from summarizer import Summarizer, TransformerSummarizer
import requests
import os

api_key = settings.DEEPGRAM_API_KEY

class SummarizationStrategy(ABC):   
    @abstractmethod
    def summarize_text(self, transcript, language="en"):
        pass

class BasicSummarization(SummarizationStrategy):
    api_url = "https://api.deepgram.com/v1/read"
    print("summarization with deepgram")
    def summarize_text(self, transcript, language="en"):
        print("step04: basic summarization - with deepgram")
        headers = {
            "Authorization": f"Token {api_key}",
            "Content-Type": "application/json"
        }
        params = {
            "summarize": "true",
            "language": "en"
        }
        data = {
            "text": transcript  # Sending direct text instead of URL
        }
        try:
            response = requests.post(
                self.api_url,
                headers=headers,
                params=params,
                json=data
            )
            response.raise_for_status()      
            # Extract summary from response
            summary = response.json().get("results", {}).get("summary", "").get("text", "")
            return summary if summary else "Failed to generate summary"         
        except requests.exceptions.RequestException as e:
            return f"Error generating summary: {str(e)}"




class AdvancedSummarization(SummarizationStrategy):
    def summarize_text(self, transcript, language):
        print(language)
        api_key = settings.OPENAI_API_KEY   
        print("step04: advanced summarization - with openai")
        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        transcript_word_number = len(transcript.split())
        print(transcript_word_number)
        print(transcript_word_number*0.1)
        
        max_words = 0
        if transcript_word_number*0.1 >300 :
            max_words = 300
        else:
            max_words = transcript_word_number*0.1
        if max_words <20:
            max_words = 50
        
        prompt = f"""
        i will provide you a meeting transcript, please summarize it in {max_words} words, in {language} language  only.
        the transcript is:
        {transcript}
        """
        data = {
            "model": "gpt-4o-mini",
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.7,
        }
        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 200:
            result = response.json()
            message_content = result['choices'][0]['message']['content']
            return message_content

        else:
            print(f"Request failed with status code {response.status_code}: {response.text}")
