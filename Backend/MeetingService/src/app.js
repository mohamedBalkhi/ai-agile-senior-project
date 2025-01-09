const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const timeout = require('connect-timeout');
const routes = require('./routes');
const logger = require('./utils/logger');

const app = express();

// CORS configuration
app.use(cors({
    origin: true,
    methods: ['GET', 'POST', 'DELETE', 'OPTIONS', 'PUT', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    exposedHeaders: ['Content-Length', 'Content-Type'],
    credentials: false,
    preflightContinue: false,
    optionsSuccessStatus: 204
}));

// Security headers
app.use(helmet({
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: { policy: "cross-origin" },
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'", "*"],
            connectSrc: ["'self'", "*"],
            mediaSrc: ["'self'", "*", "blob:"],
            imgSrc: ["'self'", "*", "data:", "blob:"],
            scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", "*"],
            styleSrc: ["'self'", "'unsafe-inline'", "*"],
            fontSrc: ["'self'", "*"],
            workerSrc: ["'self'", "blob:"],
            frameSrc: ["'self'", "*"]
        }
    }
}));

app.use(express.json());
app.use(timeout('30s'));

// Enable CORS preflight
app.options('*', cors());

// Mount API routes
app.use('/api', routes);

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        status: 'error',
        message: `Cannot ${req.method} ${req.url}`
    });
});

// Error handler
app.use((err, req, res, next) => {
    // Log the error
    logger.error('Error:', {
        method: req.method,
        url: req.url,
        error: err.message,
        stack: err.stack
    });

    // Don't send error response if headers already sent
    if (res.headersSent) {
        return next(err);
    }

    // Ensure we have a valid status code
    const statusCode = err.status && Number.isInteger(err.status) ? err.status : 500;

    // Send error response
    res.status(statusCode).json({
        status: 'error',
        message: err.message || 'Internal Server Error'
    });
});

const port = process.env.PORT || 3000;

app.listen(port, () => {
    logger.info(`Server is running on port ${port}`);
});