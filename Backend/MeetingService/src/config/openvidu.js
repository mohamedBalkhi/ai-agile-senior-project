const { OpenVidu } = require('openvidu-node-client');
const logger = require('../utils/logger');

// For local development, use the localhost URL first
const OPENVIDU_URL = process.env.OPENVIDU_URL || 'https://localhost:5443';
const OPENVIDU_SECRET = process.env.OPENVIDU_SECRET || 'MY_SECRET';

// Disable SSL verification for local development
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// Create OpenVidu instance
const openvidu = new OpenVidu(OPENVIDU_URL, OPENVIDU_SECRET);

// Add Basic Auth headers - only use the secret for basic auth
openvidu.headers = {
    'Authorization': `Basic ${Buffer.from(OPENVIDU_SECRET).toString('base64')}`,
    'Content-Type': 'application/json'
};

// Verify OpenVidu connection
async function verifyOpenViduConnection() {
    try {
        await openvidu.fetch();
        logger.info('Successfully connected to OpenVidu Server');
        return true;
    } catch (error) {
        logger.error('Failed to connect to OpenVidu Server:', {
            url: OPENVIDU_URL,
            error: error.message,
            stack: error.stack
        });
        return false;
    }
}

// Initial connection verification
verifyOpenViduConnection().then(isConnected => {
    if (!isConnected) {
        logger.warn('OpenVidu Server connection failed. Make sure the server is running and accessible.');
    }
});

logger.info(`OpenVidu configured with URL: ${OPENVIDU_URL}`);

module.exports = {
    openvidu,
    verifyOpenViduConnection
}; 