const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const timeout = require('connect-timeout');
const routes = require('./routes');
const logger = require('./utils/logger');
const { AppError, middleware: errorHandler } = require('./middleware/errorHandler');

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

// Request body parser
app.use(express.json({
    limit: '10mb',
    verify: (req, res, buf) => {
        try {
            JSON.parse(buf);
        } catch (e) {
            throw new AppError(400, 'Invalid JSON payload');
        }
    }
}));

// Timeout middleware
app.use(timeout('30s'));
app.use((req, res, next) => {
    if (!req.timedout) next();
});

// Enable CORS preflight
app.options('*', cors());

// Mount API routes
app.use('/api', routes);

// Add root route handler
app.get('/', (req, res) => {
    logger.info('Root request received', {
        headers: req.headers,
        ip: req.ip
    });
    res.status(200).json({
        status: 'OK',
        message: 'Meeting Service is running',
        version: process.env.npm_package_version || '1.0.0'
    });
});

// Handle timeout errors
app.use((err, req, res, next) => {
    if (err.timeout) {
        return next(new AppError(408, 'Request timeout'));
    }
    next(err);
});

// 404 handler for undefined routes
app.use((req, res, next) => {
    next(new AppError(404, `Cannot ${req.method} ${req.url}`));
});

// Global error handler
app.use((err, req, res, next) => {
    // Don't send error response if headers already sent
    if (res.headersSent) {
        return next(err);
    }

    // Handle body-parser errors
    if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
        return next(new AppError(400, 'Invalid request body'));
    }

    // Handle other errors
    errorHandler(err, req, res, next);
});

const host = process.env.HOST || '0.0.0.0';
const port = process.env.PORT || 3000;

app.listen(port, host, () => {
    logger.info(`Server is running on ${host}:${port}`);
    logger.info(`Health check endpoint available at http://${host}:${port}/api/health`);
});