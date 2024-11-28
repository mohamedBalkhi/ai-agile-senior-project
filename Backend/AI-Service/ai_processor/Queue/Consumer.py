import pika
import sys
import signal

# Import the process_audio function
from ai_processor.Processor.Process_audio_callback import process_audio

def setup_consumer():
    try:
        # RabbitMQ connection with better parameters
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host='localhost',
                heartbeat=600,
                blocked_connection_timeout=300
            )
        )
        channel = connection.channel()

        # Declare the queue to ensure it exists
        channel.queue_declare(
            queue='audio_queue',
            durable=True
        )

        # Set up QoS
        channel.basic_qos(prefetch_count=1)

        # Set up the consumer to listen to the queue
        channel.basic_consume(
            queue='audio_queue',
            on_message_callback=process_audio,  # Callback function to process messages
            auto_ack=False  # Manual acknowledgment to ensure reliability
        )

        # Setup graceful shutdown
        def signal_handler(sig, frame):
            print('\nShutting down consumer...')
            channel.stop_consuming()
            connection.close()
            sys.exit(0)

        signal.signal(signal.SIGINT, signal_handler)

        print("Consumer is now listening to the 'audio_queue'...")
        channel.start_consuming()

    except pika.exceptions.AMQPConnectionError as e:
        print(f"Failed to connect to RabbitMQ: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    setup_consumer()
