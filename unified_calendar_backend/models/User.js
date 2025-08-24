const mongoose = require('mongoose');

const attendeeSchema = mongoose.Schema({
    email: { type: String, required: true, lowercase: true, trim: true },
    status: { type: String, enum: ['accepted', 'declined', 'pending'], default: 'pending' },
    isOrganizer: { type: Boolean, default: false },
});

const eventSchema = mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId, // Links to our internal User model
            ref: 'User',
            required: true,
        },
        externalCalendarAccountId: { // Links to the ExternalCalendarAccount this event belongs to
            type: mongoose.Schema.Types.ObjectId,
            ref: 'ExternalCalendarAccount',
            required: true,
        },
        externalEventId: { // ID of the event on the external service (Google, Outlook), null for 'custom' app events
            type: String,
        },
        title: {
            type: String,
            required: true,
        },
        description: {
            type: String,
        },
        startTime: {
            type: Date,
            required: true,
        },
        endTime: {
            type: Date,
            required: true,
        },
        location: {
            type: String,
        },
        attendees: [attendeeSchema], // Embedded array of attendees
        isAllDay: {
            type: Boolean,
            default: false,
        },
        sourceType: { // 'google', 'outlook', 'apple', 'custom' - determines where the event originated
            type: String,
            required: true,
            enum: ['google', 'outlook', 'apple', 'custom'],
        },
        isNewlyAccepted: { // For frontend to highlight newly accepted invites (can be reset after viewing)
            type: Boolean,
            default: false,
        },
        lastSynced: { // Timestamp of last successful sync
            type: Date,
            default: Date.now,
        },
    },
    {
        timestamps: true,
    }
);

// Index for efficient querying by user and time range
eventSchema.index({ userId: 1, startTime: 1, endTime: 1 });

const Event = mongoose.model('Event', eventSchema);
module.exports = Event;
