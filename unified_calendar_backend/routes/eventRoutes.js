const express = require('express');
const router = express.Router(); // Initialize a new Express Router
const { protect } = require('../middleware/authMiddleware'); // Middleware for route protection
const {
    createEvent,
    getEvents,
    updateEvent,
    deleteEvent,
    updateAttendeeStatus,
} = require('../controllers/calendarController'); // Event controllers are still in calendarController

// --- Event Management Routes (All paths here are relative to where eventRoutes is mounted, e.g., /api/events) ---

// POST /api/events - Create a new event
router.post('/', protect, createEvent);

// GET /api/events/:userId - Get all events for a specific user
router.get('/:userId', protect, getEvents);

// PATCH /api/events/:id - Update an event
router.patch('/:id', protect, updateEvent);

// DELETE /api/events/:id - Delete an event
router.delete('/:id', protect, deleteEvent);

// PATCH /api/events/:id/attendees - Update attendee status for an event
router.patch('/:id/attendees', protect, updateAttendeeStatus);

module.exports = router; // Essential: Export this new router instance
