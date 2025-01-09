const express = require('express');
const { body, param, validationResult } = require('express-validator');
const sessionService = require('../services/sessionService');
const logger = require('../utils/logger');
const { AppError } = require('../middleware/errorHandler');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

const router = express.Router();

// Create a new session
router.post('/', 
    body('sessionId')
        .isString()
        .trim()
        .notEmpty()
        .matches(/^[a-zA-Z0-9-_]+$/)
        .withMessage('Session ID must contain only letters, numbers, hyphens and underscores'),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({ errors: errors.array() });
            }
            const { sessionId } = req.body;
            const session = await sessionService.createSession(sessionId);
            const token = await sessionService.generateToken(session);
            
            res.status(201).json({
                sessionId: session.sessionId,
                token
            });
        } catch (error) {
            next(error);
        }
    }
);

// Generate token for existing session
router.post('/:sessionId/token',
    param('sessionId').isString().trim().notEmpty(),
    body('role').isIn(['PUBLISHER', 'SUBSCRIBER']).optional(),
    async (req, res, next) => {
        try {
            const { sessionId } = req.params;
            const { role } = req.body;

            const session = await sessionService.getActiveSession(sessionId);
            if (!session) {
                throw new AppError(404, 'Session not found');
            }

            const token = await sessionService.generateToken(session, role);
            res.status(200).json({ token });
        } catch (error) {
            next(error);
        }
    }
);

// Close a session
router.delete('/:sessionId',
    param('sessionId').isString().trim().notEmpty(),
    async (req, res, next) => {
        try {
            const { sessionId } = req.params;
            const closed = await sessionService.closeSession(sessionId);
            
            if (!closed) {
                throw new AppError(404, 'Session not found');
            }
            
            res.status(200).json({ message: 'Session closed successfully' });
        } catch (error) {
            next(error);
        }
    }
);

// Get active sessions
router.get('/', async (req, res, next) => {
    try {
        const sessions = await sessionService.getActiveSessions();
        res.status(200).json({ sessions });
    } catch (error) {
        next(error);
    }
});

// Get session info
router.get('/:sessionId', 
    param('sessionId').isString().trim().notEmpty(),
    async (req, res, next) => {
        try {
            const { sessionId } = req.params;
            const sessionInfo = await sessionService.getSessionInfo(sessionId);
            res.status(200).json(sessionInfo);
        } catch (error) {
            next(error);
        }
    }
);

// Start recording
router.post('/:sessionId/recording/start',
    param('sessionId').isString().trim().notEmpty(),
    body('name').optional().isString(),
    body('hasAudio').optional().isBoolean(),
    body('hasVideo').optional().isBoolean(),
    body('outputMode').optional().isIn(['COMPOSED', 'INDIVIDUAL']),
    body('recordingLayout').optional().isIn(['BEST_FIT', 'CUSTOM']),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({ errors: errors.array() });
            }

            const { sessionId } = req.params;
            const recordingOptions = {
                name: req.body.name,
                hasAudio: req.body.hasAudio,
                hasVideo: req.body.hasVideo,
                outputMode: req.body.outputMode,
                recordingLayout: req.body.recordingLayout
            };

            const recording = await sessionService.startRecording(sessionId, recordingOptions);
            res.status(200).json(recording);
        } catch (error) {
            next(error);
        }
    }
);

// Stop recording
router.post('/:sessionId/recording/:recordingId/stop',
    param('sessionId').isString().trim().notEmpty(),
    param('recordingId').isString().trim().notEmpty(),
    async (req, res, next) => {
        try {
            const { recordingId } = req.params;
            const recording = await sessionService.stopRecording(recordingId);
            res.status(200).json(recording);
        } catch (error) {
            next(error);
        }
    }
);

// Get recording
router.get('/:sessionId/recording/:recordingId',
    param('sessionId').isString().trim().notEmpty(),
    param('recordingId').isString().trim().notEmpty(),
    async (req, res, next) => {
        try {
            const { recordingId } = req.params;
            const recording = await sessionService.getRecording(recordingId);
            res.status(200).json(recording);
        } catch (error) {
            next(error);
        }
    }
);

// List all recordings
router.get('/recordings', async (req, res, next) => {
    try {
        const recordings = await sessionService.getAllRecordings();
        res.status(200).json(recordings);
    } catch (error) {
        next(error);
    }
});

// Get recording info
router.get('/:sessionId/recording/info',
    param('sessionId').isString().trim().notEmpty(),
    async (req, res, next) => {
        try {
            const { sessionId } = req.params;
            const recordingInfo = await sessionService.getRecordingInfo(sessionId);
            
            if (!recordingInfo) {
                throw new AppError(404, 'No recording found for this session');
            }

            res.status(200).json(recordingInfo);
        } catch (error) {
            next(error);
        }
    }
);

// Get recording file
router.get('/:sessionId/recording/:recordingId/download', 
    param('sessionId').isString().trim().notEmpty(),
    param('recordingId').isString().trim().notEmpty(),
    async (req, res, next) => {
        try {
            const { recordingId } = req.params;
            const recording = await sessionService.getRecording(recordingId);
            
            if (!recording || !recording.url) {
                throw new AppError(404, 'Recording not found or not ready');
            }

            // Proxy the recording file from OpenVidu server
            const recordingUrl = recording.url;
            console.log('Fetching recording from:', recordingUrl);

            // Create proper Basic Auth header with just the secret
            const basicAuth = Buffer.from('MY_SECRET').toString('base64');

            const response = await fetch(recordingUrl, {
                headers: {
                    'Authorization': `Basic T1BFTlZJRFVBUFA6TVlfU0VDUkVU`
                }
            });

            if (!response.ok) {
                throw new AppError(response.status, `Failed to fetch recording: ${response.statusText}`);
            }

            // Get content type from response
            const contentType = response.headers.get('content-type') || 'video/webm';
            const contentLength = response.headers.get('content-length');

            // Set response headers
            res.setHeader('Content-Type', contentType);
            if (contentLength) {
                res.setHeader('Content-Length', contentLength);
            }
            res.setHeader('Content-Disposition', `attachment; filename="${recording.name || recordingId}.webm"`);

            // Stream the response
            response.body.pipe(res);

            // Handle potential errors during streaming
            response.body.on('error', (error) => {
                console.error('Error streaming recording:', error);
                if (!res.headersSent) {
                    next(new AppError(500, 'Error streaming recording'));
                }
            });

            // Clean up on finish
            res.on('finish', () => {
                console.log('Finished streaming recording:', recordingId);
            });

        } catch (error) {
            console.error('Error downloading recording:', error);
            if (!res.headersSent) {
                next(new AppError(error.status || 500, error.message || 'Failed to download recording'));
            }
        }
    }
);

// Add these routes
router.post('/:sessionId/connection', 
    param('sessionId').isString().trim().notEmpty(),
    body('role').isIn(['PUBLISHER', 'SUBSCRIBER', 'MODERATOR']).optional(),
    async (req, res, next) => {
        try {
            const { sessionId } = req.params;
            const connection = await sessionService.createConnection(sessionId, req.body);
            res.status(200).json(connection);
        } catch (error) {
            next(error);
        }
    }
);

// Handle connection events
router.post('/:sessionId/connection/:connectionId/event',
    param('sessionId').isString().trim().notEmpty(),
    param('connectionId').isString().trim().notEmpty(),
    body('event').isIn(['created', 'destroyed']).isString(),
    async (req, res, next) => {
        try {
            const { sessionId, connectionId } = req.params;
            const { event } = req.body;

            if (event === 'created') {
                await sessionService.handleConnectionCreated(sessionId, connectionId);
            } else if (event === 'destroyed') {
                await sessionService.handleConnectionDestroyed(sessionId, connectionId);
            }

            res.status(200).json({ message: 'Event handled successfully' });
        } catch (error) {
            next(error);
        }
    }
);

module.exports = router; 