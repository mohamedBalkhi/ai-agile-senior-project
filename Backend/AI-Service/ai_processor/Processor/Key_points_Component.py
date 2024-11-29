from abc import ABC, abstractmethod
from django.conf import settings
import requests

api_key = settings.DEEPGRAM_API_KEY

class KeyPointsStrategy(ABC):
    @abstractmethod
    def extract_key_points(self, summary):
        print("step06: extract key points strategy")
        pass



class BasicKeyPoints(KeyPointsStrategy):
    api_url = "https://api.deepgram.com/v1/read"
    print("key point extraction with deepgram")

    def extract_key_points(self, transcript):
        print("step06: basic key points")
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


class AdvancedKeyPoints(KeyPointsStrategy):
    def extract_key_points(self, summary):
        print("step06: advanced key points")
        return ["Advanced Key Point 1", "Advanced Key Point 2", "Advanced Key Point 3"]
