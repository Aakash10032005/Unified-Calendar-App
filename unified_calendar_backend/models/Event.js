const mongoose = require('mongoose');

const attendeeSchema = mongoose.Schema({
    email: { type: String, required: true, lowercase: true, trim: true },
    status: { type: String, enum: ['accepted', 'declined', 'pending'], default: 'pending' },
    isOrganizer: { type: Boolean, default: false },
});

const eventSchema = mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        externalCalendarAccountId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'ExternalCalendarAccount',
            required: true,
        },
        externalEventId: { type: String },
        title: { type: String, required: true },
        description: { type: String },
        startTime: { type: Date, required: true },
        endTime: { type: Date, required: true },
        location: { type: String },
        attendees: [attendeeSchema],
        isAllDay: { type: Boolean, default: false },
        sourceType: {
            type: String,
            required: true,
            enum: ['google', 'outlook', 'apple', 'custom'],
        },
        isNewlyAccepted: { type: Boolean, default: false },
        lastSynced: { type: Date, default: Date.now },
    },
    { timestamps: true }
);

eventSchema.index({ userId: 1, startTime: 1, endTime: 1 });

const Event = mongoose.models.Event || mongoose.model('Event', eventSchema);
module.exports = Event;