const express = require('express');
const { param, body, validationResult } = require('express-validator');
const roomService = require('../services/roomService');
const { AppError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');
const router = express.Router();

// Create a new room
router.post('/',
    body('roomName').isString().trim().notEmpty().withMessage('Room name is required'),
    body('metadata').optional().isObject().withMessage('Metadata must be an object'),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                throw new AppError(400, errors.array()[0].msg);
            }

            const { roomName, metadata } = req.body;
            const room = await roomService.createRoom(roomName, metadata);
            res.status(201).json(room);
        } catch (error) {
            if (error.statusCode === 409) {
                return next(error);
            }
            next(new AppError(error.statusCode || 500, error.message));
        }
    }
);

// Get room info
router.get('/:roomName',
    param('roomName').isString().trim().notEmpty().withMessage('Room name is required'),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                throw new AppError(400, errors.array()[0].msg);
            }

            const { roomName } = req.params;
            const roomInfo = await roomService.getRoomInfo(roomName);
            res.status(200).json(roomInfo);
        } catch (error) {
            if (error.statusCode === 404) {
                return next(error);
            }
            next(new AppError(error.statusCode || 500, error.message));
        }
    }
);

// Delete room
router.delete('/:roomName',
    param('roomName').isString().trim().notEmpty().withMessage('Room name is required'),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                throw new AppError(400, errors.array()[0].msg);
            }

            const { roomName } = req.params;
            const deleted = await roomService.deleteRoom(roomName);
            
            if (!deleted) {
                throw new AppError(404, 'Room not found');
            }

            res.status(200).json({ 
                status: 'success',
                message: 'Room deleted successfully'
            });
        } catch (error) {
            next(new AppError(error.statusCode || 500, error.message));
        }
    }
);

// Start room recording
router.post('/:roomName/recording/start',
    param('roomName').isString().trim().notEmpty().withMessage('Room name is required'),
    body('audioOnly').optional().isBoolean().withMessage('audioOnly must be a boolean'),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                throw new AppError(400, errors.array()[0].msg);
            }

            const { roomName } = req.params;
            const { audioOnly = true } = req.body;
            
            const recording = await roomService.startRecording(roomName, { audioOnly });
            res.status(200).json(recording);
        } catch (error) {
            if (error.statusCode === 404) {
                return next(error);
            }
            next(new AppError(error.statusCode || 500, error.message));
        }
    }
);

// Stop room recording
router.post('/:roomName/recording/stop',
    param('roomName').isString().trim().notEmpty().withMessage('Room name is required'),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                throw new AppError(400, errors.array()[0].msg);
            }

            const { roomName } = req.params;
            await roomService.stopRecording(roomName);
            res.status(200).json({ 
                status: 'success',
                message: 'Recording stopped successfully' 
            });
        } catch (error) {
            if (error.statusCode === 404) {
                return next(error);
            }
            next(new AppError(error.statusCode || 500, error.message));
        }
    }
);

// Get recordings for a room
router.get('/:roomName/recordings',
    param('roomName').isString().trim().notEmpty().withMessage('Room name is required'),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                throw new AppError(400, errors.array()[0].msg);
            }

            const { roomName } = req.params;
            const recordings = await roomService.getRecordings(roomName);
            res.status(200).json({
                status: 'success',
                recordings: recordings || []
            });
        } catch (error) {
            next(new AppError(error.statusCode || 500, error.message));
        }
    }
);

// Get recording status
router.get('/:roomName/recording/status',
    param('roomName').isString().trim().notEmpty().withMessage('Room name is required'),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                throw new AppError(400, errors.array()[0].msg);
            }

            const { roomName } = req.params;
            const status = await roomService.getRecordingStatus(roomName);
            res.status(200).json(status);
        } catch (error) {
            if (error.statusCode === 404) {
                return next(error);
            }
            next(new AppError(error.statusCode || 500, error.message));
        }
    }
);

// Generate token for room
router.post('/:roomName/token',
    param('roomName').isString().trim().notEmpty().withMessage('Room name is required'),
    body('identity').isString().trim().notEmpty().withMessage('Identity is required'),
    body('metadata').optional().isObject().withMessage('Metadata must be an object'),
    body('name').optional().isString().withMessage('Name must be a string'),
    async (req, res, next) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                throw new AppError(400, errors.array()[0].msg);
            }

            const { roomName } = req.params;
            const { identity, metadata = {}, name } = req.body;
            
            const token = await roomService.generateToken(roomName, identity, {
                ...metadata,
                name: name || metadata.name || identity
            });
            
            res.status(200).json({ token });
        } catch (error) {
            if (error.statusCode === 404) {
                return next(error);
            }
            next(new AppError(error.statusCode || 500, error.message));
        }
    }
);

module.exports = router; 