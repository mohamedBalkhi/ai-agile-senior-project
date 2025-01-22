#!/bin/bash
# Start the consumer in the background
python manage.py run_consumer &

# Start Django development server
python manage.py runserver 0.0.0.0:8000
