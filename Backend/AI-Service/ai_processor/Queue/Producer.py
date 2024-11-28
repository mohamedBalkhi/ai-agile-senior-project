import pika
import json
from django.conf import settings

class AudioQueueProducer:
    def __init__(self):
        # Connect to RabbitMQ
        self.connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
        self.channel = self.connection.channel()
        print("step05: producer")
        
        # Declare the queue (create it if it doesn't exist)
        self.channel.queue_declare(queue='audio_queue', durable=True)

    def add_audio_task(self, audio_id, audio_url, main_language, user_plan):
        task = {
            "audio_id": str(audio_id),
            "audio_url": audio_url,
            "main_language": main_language,
            "user_plan": user_plan
        }
        
        message = json.dumps(task)
        self.channel.basic_publish(
            exchange='',  # Default exchange
            routing_key='audio_queue', 
            body=message,
            properties=pika.BasicProperties(
                delivery_mode=2  # Makes the message persistent
            )
        )
        print(f"Task added to queue: {task}")

    def close(self):
        if self.connection and not self.connection.is_closed:
            self.connection.close()

    def __del__(self):
        self.close()
