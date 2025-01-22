const express = require('express');
const roomRoutes = require('./roomRoutes');

const router = express.Router();

router.use('/rooms', roomRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

module.exports = router; 