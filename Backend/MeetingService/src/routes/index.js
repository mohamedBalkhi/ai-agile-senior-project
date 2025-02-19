const express = require('express');
const roomRoutes = require('./roomRoutes');
// const roomService = require('../services/roomService');
const logger = require('../utils/logger');

const router = express.Router();

router.use('/rooms', roomRoutes);

// Enhanced health check endpoint with detailed logging
router.get('/health', async (req, res) => {
    logger.info('Health check request received', {
        headers: req.headers,
        ip: req.ip,
        path: req.path
    });
    
    try {
        // Check LiveKit connection
        // await roomService.getActiveRoom('health-check');
        
        // Basic health status
        const health = {
            status: 'OK',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            env: process.env.NODE_ENV || 'production',
        };

        logger.info('Health check passed', health);
        res.status(200).json(health);
    } catch (error) {
        logger.error('Health check failed:', error);
        res.status(503).json({
            status: 'ERROR',
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

module.exports = router; 