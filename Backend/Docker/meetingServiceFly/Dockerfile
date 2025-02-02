FROM node:20-alpine

WORKDIR /app

# Install dependencies first (for better caching)
COPY ../../MeetingService/package*.json ./
RUN npm install --omit=dev

# Copy source code
COPY ../../MeetingService .

# Set environment variables
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8082

# Expose the port
EXPOSE 8082

# Start the application
CMD ["node", "src/app.js"] 