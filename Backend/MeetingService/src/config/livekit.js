const { RoomServiceClient, AccessToken } = require('livekit-server-sdk');
const { EgressClient, SegmentedFileOutput } = require('livekit-server-sdk');
const logger = require('../utils/logger');

// LiveKit Configuration
const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY || 'APIGRZq7hLoEKF4';
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET || 'oOrBw7x0O82lLwdzVzHHLwuw4UTk68NqeGavMLG61amU';
const DOMAIN_NAME = process.env.DOMAIN_NAME || 'meeting.agilemeets.com';
const LIVEKIT_URL = `wss://${DOMAIN_NAME}`;

logger.info('LiveKit Configuration:', {
    url: LIVEKIT_URL,
    domain: DOMAIN_NAME,
    apiKeySet: !!LIVEKIT_API_KEY,
    apiSecretSet: !!LIVEKIT_API_SECRET
});

// Create LiveKit Room Service client
const roomService = new RoomServiceClient(
    LIVEKIT_URL,
    LIVEKIT_API_KEY,
    LIVEKIT_API_SECRET
);

const egressClient = new EgressClient(
    LIVEKIT_URL,
    LIVEKIT_API_KEY,
    LIVEKIT_API_SECRET
);

// MinIO Configuration
const MINIO_CONFIG = {
    accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
    secretKey: process.env.MINIO_SECRET_KEY || 'KlrKUduYHE08FUniLOf8NP4BMvSXHhp8NtabGyrtduVT',
    url: process.env.MINIO_URL || 'https://meeting.agilemeets.com/minio-console/',
    bucket: 'recordings'
};

// Verify LiveKit connection
async function verifyLiveKitConnection() {
    try {
        // Try to list rooms as a connection test
        await roomService.listRooms();
        logger.info('Successfully connected to LiveKit Server');
        return true;
    } catch (error) {
        logger.error('Failed to connect to LiveKit Server:', {
            url: LIVEKIT_URL,
            error: error.message,
            stack: error.stack
        });
        return false;
    }
}

// Initial connection verification
verifyLiveKitConnection().then(isConnected => {
    if (!isConnected) {
        logger.warn('LiveKit Server connection failed. Make sure the server is running and accessible.');
    }
});

logger.info(`LiveKit configured with URL: ${LIVEKIT_URL}`);

module.exports = {
    roomService,
    egressClient,
    AccessToken,
    LIVEKIT_API_KEY,
    LIVEKIT_API_SECRET,
    LIVEKIT_URL,
    MINIO_CONFIG,
    verifyLiveKitConnection,
    SegmentedFileOutput
}; 