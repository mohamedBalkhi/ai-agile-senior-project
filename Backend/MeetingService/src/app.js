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

const port = process.env.PORT || 3000;

app.listen(port, () => {
    logger.info(`Server is running on port ${port}`);
});