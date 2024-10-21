#!/bin/bash

# Navigate to the directory containing the docker-compose.yml file
cd ../BaseMgtService/Docker

# Build and start the services defined in docker-compose.yml
docker-compose up --build -d

# Print a message indicating the services are running
echo "BaseMgt Service and PostgreSQL database are now running."
echo "API is accessible at http://localhost:8080"
echo "PostgreSQL is accessible at localhost:5432"

# Optionally, you can tail the logs of the services
# Uncomment the following line if you want to see the logs
# docker-compose logs -f
