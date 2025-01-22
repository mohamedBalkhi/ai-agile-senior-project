FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY ../../MeetingService/package*.json ./

# Install dependencies
RUN npm install --omit=dev

# Copy source code
COPY ../../MeetingService .

# Expose the port the app runs on
EXPOSE 8082

# Start the application
CMD ["npm", "start"] 