from abc import ABC, abstractmethod
import requests
from django.conf import settings

api_key = settings.DEEPGRAM_API_KEY


class SummarizationStrategy(ABC):
    @abstractmethod
    def summarize_text(self, transcript):
        print("step04: summarization strategy")
        pass


class BasicSummarization(SummarizationStrategy):

    api_url = "https://api.deepgram.com/v1/read"

    def summarize_text(self, transcript):
        print("step04: basic summarization")
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
            summary = response.json().get("results", {}).get("summary", "")
            return summary if summary else "Failed to generate summary"
            
        except requests.exceptions.RequestException as e:
            return f"Error generating summary: {str(e)}"


class AdvancedSummarization(SummarizationStrategy):
    def summarize_text(self, transcript):
        print("step04: advanced summarization")
        return f"Advanced summary of: {transcript}"
