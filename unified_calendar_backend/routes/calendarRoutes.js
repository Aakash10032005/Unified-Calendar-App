const express = require('express');
const router = express.Router(); // Initialize an Express Router
const { protect } = require('../middleware/authMiddleware'); // Middleware for route protection
const {
    connectCalendar,
    googleCallback,
    getCalendarAccounts,
    refreshCalendar,
} = require('../controllers/calendarController'); // Controller functions for calendar logic

// --- External Calendar Connection & Account Management Routes (mounted at /api/calendars in server.js) ---
router.get('/connect/:calendarType/:userId', protect, connectCalendar);
router.get('/google/callback', googleCallback); // This route will be accessible at /api/calendars/google/callback
router.get('/accounts/:userId', protect, getCalendarAccounts);
router.post('/refresh/:accountId', protect, refreshCalendar);

module.exports = router; // Essential: Export the router instance
