# Meeting Service

A Node.js microservice for managing video conferencing sessions using OpenVidu.

## Features

- Session creation and management
- Token generation for participants
- Room management
- Webhook handling
- Real-time session operations

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- OpenVidu server running (local or cloud)

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Copy `.env.example` to `.env` and update the values:
   ```bash
   cp .env.example .env
   ```

## Configuration

Update the `.env` file with your settings:

```env
PORT=3000
NODE_ENV=development
LOG_LEVEL=info
OPENVIDU_URL=http://localhost:4443
OPENVIDU_SECRET=MY_SECRET
```

## Running the Service

Development mode:
```bash
npm run dev
```

Production mode:
```bash
npm start
```

## API Endpoints

### Sessions

- `POST /api/sessions`
  - Create a new session
  - Body: `{ "sessionId": "string" }`

- `POST /api/sessions/:sessionId/token`
  - Generate token for existing session
  - Body: `{ "role": "PUBLISHER" | "SUBSCRIBER" }`

- `DELETE /api/sessions/:sessionId`
  - Close a session

- `GET /api/sessions`
  - List all active sessions

### Health Check

- `GET /api/health`
  - Check service health

## Error Handling

The service includes comprehensive error handling with:
- Detailed error logging
- Standardized error responses
- Development/Production error formatting

## Logging

Logs are stored in:
- `error.log` - Error-level logs
- `combined.log` - All logs

## Security

- CORS protection
- Helmet security headers
- Input validation
- Environment variable configuration

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT 