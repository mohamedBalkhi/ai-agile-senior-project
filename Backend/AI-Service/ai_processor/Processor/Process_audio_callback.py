import json
from .Speech_to_text_component import EnglishSpeechToText, ArabicSpeechToText
from .Summarization_component import BasicSummarization, AdvancedSummarization
from .Key_points_Component import  AdvancedKeyPoints
from .MasterProcessor import MasterProcessor


#?    Consumer callback function to process audio tasks.

def process_audio(channel, method, properties, body):
    """
    RabbitMQ callback function for processing audio messages.
    
    Args:
        channel: The channel object
        method: The delivery method
        properties: Message properties
        body: The message body
    """
    try:
        # Parse the message body
        task = json.loads(body)
        print(f"Received Task: {task}")
        print("step02: process audio")

        # Dynamic Strategy Selection
        language = task.get("main_language")
        user_plan = task.get("user_plan")

        if language == "ar":
            speech_to_text_strategy = ArabicSpeechToText()
        else:
            speech_to_text_strategy = EnglishSpeechToText()

        if user_plan == "premium":
            summarization_strategy = AdvancedSummarization() #openai
            key_points_strategy = AdvancedKeyPoints() #openai
        else:
            summarization_strategy = BasicSummarization() #deepgram
            key_points_strategy = AdvancedKeyPoints() #openai

        processor = MasterProcessor(
            speech_to_text_strategy,
            summarization_strategy,
            key_points_strategy
        )

        # Process the task
        processor.process_task(task)
        
        # Acknowledge the message
        channel.basic_ack(delivery_tag=method.delivery_tag)
        print(f"Task {task.get('audio_id', 'unknown')} completed successfully\n")

    except json.JSONDecodeError as e:
        print(f"Invalid JSON in message: {e}")
        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
    except Exception as e:
        print(f"Error processing task: {e}")
        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

