const logger = require('../utils/logger');

class AppError extends Error {
    constructor(statusCode, message) {
        super(message);
        this.statusCode = statusCode;
        this.status = this.getStatusFromCode(statusCode);
        Error.captureStackTrace(this, this.constructor);
    }

    getStatusFromCode(statusCode) {
        if (statusCode >= 500) return 'error';
        if (statusCode >= 400) return 'fail';
        return 'success';
    }
}

const errorHandler = (err, req, res, next) => {
    err.statusCode = err.statusCode || 500;
    err.status = err.status || 'error';

    // Log error details
    logger.error('Error details:', {
        statusCode: err.statusCode,
        status: err.status,
        message: err.message,
        path: req.path,
        method: req.method,
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });

    // Handle validation errors
    if (err.name === 'ValidationError') {
        err.statusCode = 400;
        err.status = 'fail';
    }

    // Handle JWT errors
    if (err.name === 'JsonWebTokenError') {
        err.statusCode = 401;
        err.status = 'fail';
        err.message = 'Invalid token. Please log in again.';
    }

    // Handle JWT expiration
    if (err.name === 'TokenExpiredError') {
        err.statusCode = 401;
        err.status = 'fail';
        err.message = 'Your token has expired. Please log in again.';
    }

    // Handle LiveKit errors
    if (err.message.includes('LiveKit')) {
        err.statusCode = err.statusCode || 503;
        err.status = 'error';
        err.message = 'Video service temporarily unavailable. Please try again later.';
    }

    // Prepare response object
    const errorResponse = {
        status: err.status,
        message: err.message,
        code: err.statusCode,
        ...(process.env.NODE_ENV === 'development' && {
            stack: err.stack,
            path: req.path,
            method: req.method
        })
    };

    // Send error response
    res.status(err.statusCode).json(errorResponse);
};

module.exports = {
    AppError,
    middleware: errorHandler
}; 