from django.core.management.base import BaseCommand
from ai_processor.Queue.Consumer import setup_consumer


class Command(BaseCommand):
    help = 'Starts the RabbitMQ consumer for audio processing'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting Audio Queue Consumer...'))
        try:
            setup_consumer()
        except KeyboardInterrupt:
            self.stdout.write(self.style.WARNING('Stopping consumer...'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error: {str(e)}')) 