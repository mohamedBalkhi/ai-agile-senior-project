const express = require('express');
const sessionRoutes = require('./sessionRoutes');

const router = express.Router();

router.use('/sessions', sessionRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

module.exports = router; 