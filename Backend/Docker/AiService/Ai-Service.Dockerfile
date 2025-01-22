FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY ../../AI-Service/Requirements.txt .
RUN pip install --no-cache-dir -r Requirements.txt

# Copy project files
COPY ../../AI-Service .

# Create audios directory
RUN mkdir -p audios

# Make start script executable
RUN chmod +x start.sh

# Expose port
EXPOSE 8000

# Command to run both services
CMD ["./start.sh"]
