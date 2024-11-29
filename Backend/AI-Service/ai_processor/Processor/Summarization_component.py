from abc import ABC, abstractmethod
from django.conf import settings
from transformers import pipeline

api_key = settings.DEEPGRAM_API_KEY


class SummarizationStrategy(ABC):
    @abstractmethod
    def summarize_text(self, transcript):
        print("step04: summarization strategy")
        pass


class BasicSummarization(SummarizationStrategy):

    def summarize_text(self, text):
        print("step04: basic summarization - with bart")
        try:
            if not text or len(text.strip()) == 0:
                return "No text provided for summarization."

            model_name = "facebook/bart-large-cnn"
            summarizer = pipeline("summarization", model=model_name)
            
            # Calculate appropriate lengths based on input text
            text_length = len(text.split())
            max_length = 50  # Cap at 350 tokens
            min_length = 100 # At least 30 tokens, at most 300
            
            summary = summarizer(
                text, 
                max_length=200,
                min_length=100,
                do_sample=False,
                truncation=True
            )
            
            if summary and len(summary) > 0:
                return summary[0]["summary_text"]
            else:
                return "Could not generate summary."
                
        except Exception as e:
            print(f"Error in summarization: {str(e)}")
            return f"Summarization failed: {str(e)}"


class AdvancedSummarization(SummarizationStrategy):
    def summarize_text(self, transcript):
        print("step04: advanced summarization")
        return f"Advanced summary of: {transcript}"
