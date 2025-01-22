# Start from the RabbitMQ management image
FROM rabbitmq:3.13-management

# Install curl (if not already included)
RUN apt-get update && apt-get install -y curl

# Create a directory to hold plugins
RUN mkdir -p /plugins

# Download the delayed message exchange plugin (.ez file) matching your RabbitMQ major/minor version
# Check https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases for the latest 3.13.x
RUN curl -L -o /plugins/rabbitmq_delayed_message_exchange-3.13.0.ez \
    https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v3.13.0/rabbitmq_delayed_message_exchange-3.13.0.ez

RUN rabbitmq-plugins enable rabbitmq_management rabbitmq_prometheus
# Enable the plugin offline so RabbitMQ loads it on startup
RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange 


# Expose ports: broker (5672) and management console (15672)
EXPOSE 5672 15672
