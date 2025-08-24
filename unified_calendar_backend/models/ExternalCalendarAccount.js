const mongoose = require('mongoose');

const externalCalendarAccountSchema = mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId, // Links to our internal User model
            ref: 'User',
            required: true,
        },
        calendarType: { // 'google', 'outlook', 'apple', 'custom'
            type: String,
            required: true,
            enum: ['google', 'outlook', 'apple', 'custom'],
        },
        externalCalendarId: { // Primary calendar ID from the external service (e.g., Google 'primary'), or a unique ID for 'custom'
            type: String,
            required: true,
        },
        accountName: { // User-friendly name for the calendar
            type: String,
            required: true,
        },
        accountEmail: { // Email associated with the external account (or placeholder for 'custom')
            type: String,
            required: true,
        },
        displayColor: { // Hex color string for UI display (e.g., #FF4285F4 for Google blue)
            type: String,
            default: '#FF888888', // Default grey
        },
        accessToken: { // Encrypted access token for external API
            type: String,
            required: true, // Mark required, but 'N/A' for custom events
        },
        refreshToken: { // Encrypted refresh token for external API (long-lived)
            type: String,
            required: true, // Mark required, but 'N/A' for custom events
        },
        expiresAt: { // When the access token expires
            type: Date,
            required: true, // Mark required, but far future for custom events
        },
        lastSyncToken: { // For incremental sync with Google/Outlook APIs (optional)
            type: String,
        },
    },
    {
        timestamps: true,
    }
);

const ExternalCalendarAccount = mongoose.model('ExternalCalendarAccount', externalCalendarAccountSchema);
module.exports = ExternalCalendarAccount;
