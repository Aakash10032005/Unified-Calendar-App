const asyncHandler = require('express-async-handler');
const { OAuth2Client } = require('google-auth-library');
const { google } = require('googleapis');
// const { Client } = require('@microsoft/microsoft-graph-client'); // Commented out Outlook
// const { ConfidentialClientApplication } = require('@azure/msal-node'); // Commented out Outlook
const ExternalCalendarAccount = require('../models/ExternalCalendarAccount');
const Event = require('../models/Event');
const User = require('../models/User'); // Import User model to confirm user exists
require('dotenv').config();

// --- Google Calendar Setup ---
const googleOAuth2Client = new OAuth2Client(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_REDIRECT_URI
);

// --- Outlook (Microsoft Graph) Setup ---
// Commented out Outlook MSAL configuration
// const msalConfig = {
//     auth: {
//         clientId: process.env.OUTLOOK_CLIENT_ID,
//         authority: `https://login.microsoftonline.com/${process.env.OUTLOOK_TENANT_ID}`,
//         clientSecret: process.env.OUTLOOK_CLIENT_SECRET,
//     },
// };
// const pca = new ConfidentialClientApplication(msalConfig);
// const outlookScopes = ['openid', 'profile', 'email', 'offline_access', 'Calendars.ReadWrite'];


// --- Helper: Encrypt/Decrypt Tokens (Basic for hackathon, use a strong library like crypto for production) ---
// IMPORTANT: For production, use a proper encryption library (e.g., Node's crypto module with AES)
// This simple base64 encoding is NOT secure for production secrets.
const encrypt = (text) => {
    if (!text) return 'N/A'; // Handle null/empty for 'custom' accounts or missing tokens
    return Buffer.from(text).toString('base64');
};

const decrypt = (encryptedText) => {
    if (encryptedText === 'N/A') return 'N/A'; // Handle 'N/A' for 'custom' accounts or missing tokens
    return Buffer.from(encryptedText, 'base64').toString('utf8');
};


// @desc    Initiate OAuth2 flow for connecting external calendars
// @route   GET /api/calendars/connect/:calendarType/:userId
// @access  Private
const connectCalendar = asyncHandler(async (req, res) => {
    const { calendarType, userId } = req.params;

    // Verify the user exists and matches the authenticated user (optional but good practice)
    if (req.userId.toString() !== userId.toString()) {
        res.status(403);
        throw new Error('Not authorized to connect calendars for this user.');
    }

    switch (calendarType.toLowerCase()) {
        case 'google':
            const googleAuthUrl = googleOAuth2Client.generateAuthUrl({
                access_type: 'offline', // Request a refresh token
                scope: ['https://www.googleapis.com/auth/calendar', 'profile', 'email'],
                state: userId.toString(), // Pass userId to identify user on callback
                prompt: 'consent', // Always prompt for consent to ensure refresh token is issued
            });
            res.json({ authUrl: googleAuthUrl });
            break;
        // case 'outlook': // Commented out Outlook connection logic
        //     const outlookAuthUrlParams = {
        //         scopes: outlookScopes,
        //         redirectUri: process.env.OUTLOOK_REDIRECT_URI,
        //         prompt: 'consent', // Always prompt for consent
        //         state: userId.toString(), // Pass userId
        //     };
        //     const outlookAuthCodeUrl = await pca.getAuthCodeUrl(outlookAuthUrlParams);
        //     res.json({ authUrl: outlookAuthCodeUrl });
        //     break;
        case 'apple':
            res.status(400);
            throw new Error('Apple Calendar direct OAuth integration is not fully supported via web APIs. Consider CalDAV or manual import.');
        default:
            res.status(400);
            throw new Error('Unsupported calendar type');
    }
});

// @desc    Google OAuth2 Callback Handler
// @route   GET /api/calendars/google/callback
// @access  Public (internally tied to OAuth flow)
const googleCallback = asyncHandler(async (req, res) => {
    const { code, state } = req.query; // 'state' will contain our userId

    if (!code || !state) {
        res.status(400);
        throw new Error('Google OAuth callback: Missing code or state.');
    }

    const userId = state;

    try {
        const { tokens } = await googleOAuth2Client.getToken(code);
        googleOAuth2Client.setCredentials(tokens);

        // Fetch user info to get primary email and display name
        const oauth2 = google.oauth2({
            auth: googleOAuth2Client,
            version: 'v2',
        });
        const userInfo = await oauth2.userinfo.get();
        const userEmail = userInfo.data.email;
        const accountName = userInfo.data.name || userEmail;


        // Get the primary Google Calendar ID
        const calendarService = google.calendar({ version: 'v3', auth: googleOAuth2Client });
        const calendarList = await calendarService.calendarList.list();
        const primaryCalendar = calendarList.data.items.find(cal => cal.primary);

        if (!primaryCalendar) {
            throw new Error('Could not find primary Google Calendar.');
        }

        // Store external account details
        let externalAccount = await ExternalCalendarAccount.findOneAndUpdate(
            { userId: userId, calendarType: 'google', accountEmail: userEmail },
            {
                userId,
                calendarType: 'google',
                externalCalendarId: primaryCalendar.id,
                accountName: accountName,
                accountEmail: userEmail,
                accessToken: encrypt(tokens.access_token), // Encrypt
                refreshToken: encrypt(tokens.refresh_token), // Encrypt
                expiresAt: new Date(Date.now() + tokens.expires_in * 1000),
                lastSyncToken: null, // Will be set on first sync
                displayColor: '#FF4285F4', // Default Google blue
            },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );

        // Trigger initial sync for this account
        await syncExternalCalendar(externalAccount._id, userId);

        // Redirect back to the Flutter app (e.g., a deep link or a simple success page)
        // For a hackathon, you can redirect to a simple page that says "Success! You can close this tab."
        // In a real app, use a custom URL scheme (deep link) like `myapp://auth?status=success&calendarType=google`
        res.send(`
            <script>
                // This script attempts to close the window, which works in some contexts.
                // For a proper Flutter integration, a deep link should be used.
                window.close();
                // window.location.href = 'unifiedcalendarapp://auth?status=success&calendarType=google';
            </script>
            <h1>Google Calendar Connected!</h1>
            <p>You can close this window and return to the app.</p>
        `);
    } catch (error) {
        console.error('Google OAuth callback error:', error);
        res.status(500).send(`
            <h1>Google Calendar Connection Failed</h1>
            <p>Error: ${error.message}</p>
            <p>Please close this window and try again in the app.</p>
        `);
    }
});

// @desc    Outlook (Microsoft Graph) OAuth2 Callback Handler
// @route   GET /api/calendars/outlook/callback
// @access  Public (internally tied to OAuth flow)
// Commented out Outlook callback logic
/*
const outlookCallback = asyncHandler(async (req, res) => {
    const { code, state } = req.query; // 'state' will contain our userId

    if (!code || !state) {
        res.status(400);
        throw new Error('Outlook OAuth callback: Missing code or state.');
    }

    const userId = state;

    try {
        const tokenResponse = await pca.acquireTokenByCode({
            code,
            scopes: outlookScopes,
            redirectUri: process.env.OUTLOOK_REDIRECT_URI,
        });

        const accessToken = tokenResponse.accessToken;
        const refreshToken = tokenResponse.refreshToken; // This might not always be present or needs specific scope

        // Fetch user details with the access token
        const graphClient = Client.init({
            authProvider: (done) => {
                done(null, accessToken);
            },
        });

        const userDetails = await graphClient.api('/me').get();
        const userEmail = userDetails.mail || userDetails.userPrincipalName;
        const accountName = userDetails.displayName || userEmail;

        // Get the default Outlook Calendar ID
        const calendars = await graphClient.api('/me/calendars').get();
        const defaultCalendar = calendars.value.find(cal => cal.isDefaultCalendar);

        if (!defaultCalendar) {
            throw new Error('Could not find default Outlook Calendar.');
        }

        // Store external account details
        let externalAccount = await ExternalCalendarAccount.findOneAndUpdate(
            { userId: userId, calendarType: 'outlook', accountEmail: userEmail },
            {
                userId,
                calendarType: 'outlook',
                externalCalendarId: defaultCalendar.id,
                accountName: accountName,
                accountEmail: userEmail,
                accessToken: encrypt(accessToken),
                refreshToken: encrypt(refreshToken), // Ensure refresh token is available and encrypted
                expiresAt: new Date(tokenResponse.expiresOn.getTime()),
                lastSyncToken: null, // Microsoft Graph uses delta queries, not sync tokens
                displayColor: '#FF0078D4', // Default Outlook blue
            },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );

        // Trigger initial sync
        await syncExternalCalendar(externalAccount._id, userId);

        res.send(`
            <script>
                window.close(); // Attempt to close the browser tab
                // In a real app, you would deep link back to Flutter:
                // window.location.href = 'unifiedcalendarapp://auth?status=success&calendarType=outlook';
            </script>
            <h1>Outlook Calendar Connected!</h1>
            <p>You can close this window and return to the app.</p>
        `);
    } catch (error) {
        console.error('Outlook OAuth callback error:', error);
        res.status(500).send(`
            <h1>Outlook Calendar Connection Failed</h1>
            <p>Error: ${error.message}</p>
            <p>Please close this window and try again in the app.</p>
        `);
    }
});
*/


// @desc    Get all connected external calendar accounts for a user
// @route   GET /api/calendars/accounts/:userId
// @access  Private
const getCalendarAccounts = asyncHandler(async (req, res) => {
    const { userId } = req.params;

    if (req.userId.toString() !== userId.toString()) {
        res.status(403);
        throw new Error('Not authorized to view calendars for this user.');
    }

    const accounts = await ExternalCalendarAccount.find({ userId });
    res.json(accounts);
});


// @desc    Sync events from a specific external calendar account
// @route   POST /api/calendars/refresh/:accountId
// @access  Private
const refreshCalendar = asyncHandler(async (req, res) => {
    const { accountId } = req.params;

    const account = await ExternalCalendarAccount.findById(accountId);

    if (!account) {
        res.status(404);
        throw new Error('Calendar account not found.');
    }

    if (req.userId.toString() !== account.userId.toString()) {
        res.status(403);
        throw new Error('Not authorized to refresh this calendar.');
    }

    await syncExternalCalendar(account._id, account.userId);

    res.json({ message: 'Calendar refresh initiated.' });
});

// --- Core Sync Logic (called internally) ---
const syncExternalCalendar = async (accountId, userId) => {
    const account = await ExternalCalendarAccount.findById(accountId);
    if (!account) {
        console.error(`Sync error: Account ${accountId} not found.`);
        return;
    }

    let accessToken = decrypt(account.accessToken);
    let refreshToken = decrypt(account.refreshToken);

    try {
        // 1. Check/Refresh Access Token
        let currentExpiresAt = new Date(account.expiresAt);
        if (currentExpiresAt <= new Date()) { // Token has expired or is about to
            console.log(`Access token for ${account.calendarType} (ID: ${accountId}) expired. Attempting refresh.`);
            if (account.calendarType === 'google') {
                googleOAuth2Client.setCredentials({ refresh_token: refreshToken });
                const refreshedTokens = await googleOAuth2Client.refreshAccessToken();
                accessToken = refreshedTokens.credentials.access_token;
                refreshToken = refreshedTokens.credentials.refresh_token || refreshToken; // Refresh token might not change
                account.accessToken = encrypt(accessToken);
                account.refreshToken = encrypt(refreshToken);
                account.expiresAt = new Date(Date.now() + refreshedTokens.credentials.expires_in * 1000);
                await account.save();
                googleOAuth2Client.setCredentials({ access_token: accessToken }); // Update client
            }
            // Commented out Outlook token refresh logic
            /*
            else if (account.calendarType === 'outlook') {
                const clientCredentialRequest = {
                    scopes: outlookScopes,
                    refreshToken: refreshToken,
                };
                const response = await pca.acquireTokenByRefreshToken(clientCredentialRequest);
                accessToken = response.accessToken;
                refreshToken = response.refreshToken || refreshToken;
                account.accessToken = encrypt(accessToken);
                account.refreshToken = encrypt(refreshToken);
                account.expiresAt = new Date(response.expiresOn.getTime());
                await account.save();
            }
            */
            console.log(`Access token for ${account.calendarType} (ID: ${accountId}) refreshed successfully.`);
        }

        // 2. Fetch Events
        let externalEvents = [];
        if (account.calendarType === 'google') {
            const calendarService = google.calendar({ version: 'v3', auth: googleOAuth2Client });
            const response = await calendarService.events.list({
                calendarId: account.externalCalendarId,
                timeMin: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString(), // Events from last year
                timeMax: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(), // Events for next year
                singleEvents: true, // Expand recurring events
                orderBy: 'startTime',
                // Using syncToken for incremental updates
                syncToken: account.lastSyncToken,
            });

            // Handle 410 (GONE) error - full sync required
            if (response.status === 410) {
                console.warn(`Google Calendar sync token expired for account ${accountId}. Performing full re-sync.`);
                account.lastSyncToken = null; // Clear token to force full sync
                await account.save();
                // Re-run sync to get full data
                return await syncExternalCalendar(accountId, userId);
            }

            externalEvents = response.data.items || [];
            account.lastSyncToken = response.data.nextSyncToken || account.lastSyncToken; // Update sync token
            await account.save();

        }
        // Commented out Outlook event fetching logic
        /*
        else if (account.calendarType === 'outlook') {
            const graphClient = Client.init({
                authProvider: (done) => {
                    done(null, accessToken);
                },
            });

            // Use delta query for incremental updates
            let request = graphClient.api(`/me/calendars/${account.externalCalendarId}/events`)
                .select('id,subject,bodyPreview,start,end,location,isAllDay,attendees,organizer,webLink')
                .filter(`start/dateTime ge '${new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString()}' and end/dateTime le '${new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()}'`); // Filter by date range

            // Outlook delta queries: first call without token, subsequent with @odata.nextLink or @odata.deltaLink
            // Simplified for hackathon: Fetching all events within a range for now, delta logic is more complex
            const response = await request.get();
            externalEvents = response.value || [];

            // TODO: Implement proper delta query handling for Outlook (using @odata.deltaLink)
            // This would involve storing and using the deltaLink from previous responses.
        }
        */
        else if (account.calendarType === 'apple') {
            // Apple Calendar (CalDAV) - Read-only approach for hackathon
            // This is a highly simplified placeholder. Full CalDAV client is complex.
            // You might use a library like 'caldav-ts' if you were using TypeScript
            // and had server-side access to a CalDAV endpoint, potentially requiring
            // app-specific passwords or more complex setup.
            console.log(`Skipping direct sync for Apple Calendar account ${accountId}. Manual import/read-only might be implemented.`);
            return;
        }

        // 3. Process and Store Events in MongoDB
        // The rest of the sync logic below handles events from 'google', 'apple', or 'custom'
        // and doesn't explicitly need to be commented out as long as 'outlook' events
        // are not being fetched into externalEvents.
        const currentLocalEvents = await Event.find({
            externalCalendarAccountId: account._id,
        }).select('externalEventId'); // Only fetch externalEventId to check for existing

        const existingEventIds = new Set(currentLocalEvents.map(e => e.externalEventId));
        const eventsToUpdate = [];
        const eventsToCreate = [];
        const eventsToDeleteIds = new Set(existingEventIds); // Assume all existing are to be deleted unless found in externalEvents

        for (const extEvent of externalEvents) {
            const eventId = extEvent.id || extEvent.iCalUId; // Google uses 'id', Outlook uses 'id'
            if (!eventId) continue; // Skip events without a valid ID

            // Determine attendee status for the current authenticated user (if an attendee)
            let currentUserStatus = 'unknown'; // Default if not found
            let isOrganizer = false;
            const eventAttendees = extEvent.attendees ? extEvent.attendees.map(att => {
                const email = att.emailAddress?.address || att.email;
                const status = att.status?.response || 'needsAction'; // Google: 'accepted', 'declined', 'needsAction'; Outlook: 'accepted', 'declined', 'tentativelyAccepted', 'notResponded'
                const isOrg = (extEvent.organizer?.emailAddress?.address === email) || (att.type === 'organizer');

                if (email === account.accountEmail) { // If this attendee is the connected account owner
                    currentUserStatus = status === 'accepted' || status === 'tentativelyAccepted' ? 'accepted' : status === 'declined' ? 'declined' : 'pending';
                    isOrganizer = isOrg;
                }

                return {
                    email: email,
                    status: status === 'accepted' || status === 'tentativelyAccepted' ? 'accepted' : status === 'declined' ? 'declined' : 'pending',
                    isOrganizer: isOrg,
                };
            }) : [];

            if (existingEventIds.has(eventId)) {
                eventsToUpdate.push(extEvent);
                eventsToDeleteIds.delete(eventId); // Don't delete this one
            } else {
                eventsToCreate.push(extEvent);
            }

            // Also update the isNewlyAccepted flag here if an invite changes to accepted
            // This logic can be more sophisticated (e.g., check `updated` timestamp)
        }

        // Delete events no longer present in external calendar
        if (eventsToDeleteIds.size > 0) {
            await Event.deleteMany({ externalCalendarAccountId: account._id, externalEventId: { $in: Array.from(eventsToDeleteIds) } });
            console.log(`Deleted ${eventsToDeleteIds.size} old events for account ${accountId}.`);
        }

        // Create new events
        for (const extEvent of eventsToCreate) {
            await Event.create({
                userId: userId,
                externalCalendarAccountId: account._id,
                externalEventId: extEvent.id || extEvent.iCalUId,
                title: extEvent.summary || extEvent.subject,
                description: extEvent.description || extEvent.bodyPreview,
                startTime: new Date(extEvent.start.dateTime || extEvent.start.date),
                endTime: new Date(extEvent.end.dateTime || extEvent.end.date),
                location: extEvent.location?.displayName || extEvent.location,
                isAllDay: extEvent.start.date && !extEvent.start.dateTime, // Google: date only for all-day; Outlook: isAllDay boolean
                attendees: extEvent.attendees ? extEvent.attendees.map(att => ({
                    email: att.emailAddress?.address || att.email,
                    status: att.responseStatus || (att.status?.response === 'accepted' || att.status?.response === 'tentativelyAccepted' ? 'accepted' : 'declined' ? 'declined' : 'pending'),
                    isOrganizer: (extEvent.organizer?.emailAddress?.address === (att.emailAddress?.address || att.email)) || (att.type === 'organizer'),
                })) : [],
                sourceType: account.calendarType,
                isNewlyAccepted: false, // Set to true if a pending invite changes to accepted later
            });
        }
        console.log(`Created ${eventsToCreate.length} new events for account ${accountId}.`);


        // Update existing events
        for (const extEvent of eventsToUpdate) {
            const eventId = extEvent.id || extEvent.iCalUId;
            const existingLocalEvent = await Event.findOne({ externalCalendarAccountId: account._id, externalEventId: eventId });

            if (existingLocalEvent) {
                let currentUserResponseStatus = existingLocalEvent.attendees.find(att => att.email === account.accountEmail)?.status;
                let newCurrentUserResponseStatus = extEvent.attendees?.find(att => att.emailAddress?.address || att.email === account.accountEmail)?.status?.response;
                if (newCurrentUserResponseStatus === 'accepted' || newCurrentUserResponseStatus === 'tentativelyAccepted') newCurrentUserResponseStatus = 'accepted';
                else if (newCurrentUserResponseStatus === 'declined') newCurrentUserResponseStatus = 'declined';
                else newCurrentUserResponseStatus = 'pending';

                existingLocalEvent.title = extEvent.summary || extEvent.subject;
                existingLocalEvent.description = extEvent.description || extEvent.bodyPreview;
                existingLocalEvent.startTime = new Date(extEvent.start.dateTime || extEvent.start.date);
                existingLocalEvent.endTime = new Date(extEvent.end.dateTime || extEvent.end.date);
                existingLocalEvent.location = extEvent.location?.displayName || extEvent.location;
                existingLocalEvent.isAllDay = extEvent.start.date && !extEvent.start.dateTime || extEvent.isAllDay;
                existingLocalEvent.attendees = extEvent.attendees ? extEvent.attendees.map(att => ({
                    email: att.emailAddress?.address || att.email,
                    status: att.responseStatus || (att.status?.response === 'accepted' || att.status?.response === 'tentativelyAccepted' ? 'accepted' : 'declined' ? 'declined' : 'pending'),
                    isOrganizer: (extEvent.organizer?.emailAddress?.address === (att.emailAddress?.address || att.email)) || (att.type === 'organizer'),
                })) : [];
                // Set isNewlyAccepted if user's status changed from pending to accepted
                if (currentUserResponseStatus === 'pending' && newCurrentUserResponseStatus === 'accepted') {
                    existingLocalEvent.isNewlyAccepted = true;
                } else {
                    existingLocalEvent.isNewlyAccepted = false; // Reset after viewed
                }
                existingLocalEvent.lastSynced = Date.now();
                await existingLocalEvent.save();
            }
        }
        console.log(`Updated ${eventsToUpdate.length} existing events for account ${accountId}.`);

    } catch (error) {
        console.error(`Error syncing calendar ${account.calendarType} (ID: ${accountId}):`, error);
        // Implement exponential backoff for retries here in a robust production system
    }
};

// @desc    Create a new event in our DB and external calendar (if sourceType is not 'custom')
// @route   POST /api/events
// @access  Private
const createEvent = asyncHandler(async (req, res) => {
    const {
        title,
        description,
        startTime,
        endTime,
        location,
        attendees,
        isAllDay,
        sourceType,
        externalCalendarAccountId, // This is our internal _id for ExternalCalendarAccount
        userId,
    } = req.body;

    if (req.userId.toString() !== userId.toString()) {
        res.status(403);
        throw new Error('Not authorized to create events for this user.');
    }

    const targetAccount = await ExternalCalendarAccount.findById(externalCalendarAccountId);

    if (!targetAccount || targetAccount.userId.toString() !== userId.toString()) {
        res.status(400);
        throw new Error('Invalid or unauthorized external calendar account provided.');
    }

    // If external source, create event via their API first
    let extEventId;
    if (sourceType !== 'custom') {
        const accessToken = decrypt(targetAccount.accessToken);
        if (sourceType === 'google') {
            googleOAuth2Client.setCredentials({ access_token: accessToken });
            const calendarService = google.calendar({ version: 'v3', auth: googleOAuth2Client });
            const googleEvent = {
                summary: title,
                description: description,
                location: location,
                start: {
                    dateTime: isAllDay ? undefined : new Date(startTime).toISOString(),
                    date: isAllDay ? new Date(startTime).toISOString().split('T')[0] : undefined,
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone, // Use server's timezone for consistency
                },
                end: {
                    dateTime: isAllDay ? undefined : new Date(endTime).toISOString(),
                    date: isAllDay ? new Date(endTime).toISOString().split('T')[0] : undefined,
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                attendees: attendees.map(att => ({ email: att.email })),
                reminders: {
                    useDefault: true,
                },
            };
            const response = await calendarService.events.insert({
                calendarId: targetAccount.externalCalendarId,
                resource: googleEvent,
            });
            extEventId = response.data.id;
        }
        // Commented out Outlook event creation logic
        /*
        else if (sourceType === 'outlook') {
            const graphClient = Client.init({
                authProvider: (done) => {
                    done(null, accessToken);
                },
            });
            const outlookEvent = {
                subject: title,
                body: {
                    contentType: 'HTML',
                    content: description,
                },
                start: {
                    dateTime: new Date(startTime).toISOString(),
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                end: {
                    dateTime: new Date(endTime).toISOString(),
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                location: {
                    displayName: location,
                },
                isAllDay: isAllDay,
                attendees: attendees.map(att => ({ emailAddress: { address: att.email }, type: 'required' })),
            };
            const response = await graphClient.api(`/me/calendars/${targetAccount.externalCalendarId}/events`).post(outlookEvent);
            extEventId = response.data.id;
        }
        */
    }

    // Save event to our database
    const event = await Event.create({
        userId,
        externalCalendarAccountId: targetAccount._id,
        externalEventId: extEventId, // Will be null for custom events
        title,
        description,
        startTime,
        endTime,
        location,
        attendees,
        isAllDay,
        sourceType,
        isNewlyAccepted: false,
    });

    res.status(201).json({ message: 'Event created successfully', event });
});


// @desc    Get all events for a specific user
// @route   GET /api/events/:userId
// @access  Private
const getEvents = asyncHandler(async (req, res) => {
    const { userId } = req.params;

    if (req.userId.toString() !== userId.toString()) {
        res.status(403);
        throw new Error('Not authorized to view events for this user.');
    }

    const events = await Event.find({ userId: userId }).populate('externalCalendarAccountId');
    res.json(events);
});

// @desc    Update an event
// @route   PATCH /api/events/:id
// @access  Private
const updateEvent = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const {
        title,
        description,
        startTime,
        endTime,
        location,
        attendees,
        isAllDay,
    } = req.body;

    let event = await Event.findById(id);

    if (!event) {
        res.status(404);
        throw new Error('Event not found.');
    }

    if (req.userId.toString() !== event.userId.toString()) {
        res.status(403);
        throw new Error('Not authorized to update this event.');
    }

    const targetAccount = await ExternalCalendarAccount.findById(event.externalCalendarAccountId);

    if (!targetAccount) {
        res.status(400);
        throw new Error('Associated external calendar account not found.');
    }


    // Update external calendar if it's not a 'custom' event
    if (event.sourceType !== 'custom' && event.externalEventId) {
        const accessToken = decrypt(targetAccount.accessToken);
        if (targetAccount.calendarType === 'google') {
            googleOAuth2Client.setCredentials({ access_token: accessToken });
            const calendarService = google.calendar({ version: 'v3', auth: googleOAuth2Client });
            const googleEvent = {
                summary: title,
                description: description,
                location: location,
                start: {
                    dateTime: isAllDay ? undefined : new Date(startTime).toISOString(),
                    date: isAllDay ? new Date(startTime).toISOString().split('T')[0] : undefined,
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                end: {
                    dateTime: isAllDay ? undefined : new Date(endTime).toISOString(),
                    date: isAllDay ? new Date(endTime).toISOString().split('T')[0] : undefined,
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                attendees: attendees.map(att => ({ email: att.email })),
            };
            await calendarService.events.patch({
                calendarId: targetAccount.externalCalendarId,
                eventId: event.externalEventId,
                resource: googleEvent,
            });
        }
        // Commented out Outlook event update logic
        /*
        else if (targetAccount.calendarType === 'outlook') {
            const graphClient = Client.init({
                authProvider: (done) => {
                    done(null, accessToken);
                },
            });
            const outlookEvent = {
                subject: title,
                body: {
                    contentType: 'HTML',
                    content: description,
                },
                start: {
                    dateTime: new Date(startTime).toISOString(),
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                end: {
                    dateTime: new Date(endTime).toISOString(),
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                location: {
                    displayName: location,
                },
                isAllDay: isAllDay,
                attendees: attendees.map(att => ({ emailAddress: { address: att.email }, type: 'required' })),
            };
            await graphClient.api(`/me/calendars/${targetAccount.externalCalendarId}/events/${event.externalEventId}`).patch(outlookEvent);
        }
        */
    }

    // Update event in our database
    event.title = title;
    event.description = description;
    event.startTime = startTime;
    event.endTime = endTime;
    event.location = location;
    event.attendees = attendees;
    event.isAllDay = isAllDay;
    event.lastSynced = Date.now(); // Mark as updated

    await event.save();

    res.json({ message: 'Event updated successfully', event });
});


// @desc    Delete an event
// @route   DELETE /api/events/:id
// @access  Private
const deleteEvent = asyncHandler(async (req, res) => {
    const { id } = req.params;

    const event = await Event.findById(id);

    if (!event) {
        res.status(404);
        throw new Error('Event not found.');
    }

    if (req.userId.toString() !== event.userId.toString()) {
        res.status(403);
        throw new Error('Not authorized to delete this event.');
    }

    // Delete from external calendar if it's not a 'custom' event
    if (event.sourceType !== 'custom' && event.externalEventId) {
        const targetAccount = await ExternalCalendarAccount.findById(event.externalCalendarAccountId);
        if (targetAccount) {
            const accessToken = decrypt(targetAccount.accessToken);
            if (targetAccount.calendarType === 'google') {
                googleOAuth2Client.setCredentials({ access_token: accessToken });
                const calendarService = google.calendar({ version: 'v3', auth: googleOAuth2Client });
                await calendarService.events.delete({
                    calendarId: targetAccount.externalCalendarId,
                    eventId: event.externalEventId,
                });
            }
            // Commented out Outlook event deletion logic
            /*
            else if (targetAccount.calendarType === 'outlook') {
                const graphClient = Client.init({
                    authProvider: (done) => {
                        done(null, accessToken);
                    },
                });
                await graphClient.api(`/me/calendars/${targetAccount.externalCalendarId}/events/${event.externalEventId}`).delete();
            }
            */
        }
    }

    await event.deleteOne(); // Use deleteOne() for Mongoose 6+

    res.json({ message: 'Event removed successfully' });
});


// @desc    Update attendee status for an event (Accept/Decline invite)
// @route   PATCH /api/events/:id/attendees
// @access  Private
const updateAttendeeStatus = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { attendeeEmail, status } = req.body; // status: 'accepted', 'declined', 'pending'

    let event = await Event.findById(id);

    if (!event) {
        res.status(404);
        throw new Error('Event not found.');
    }

    // Ensure the user trying to update their status is the authenticated user
    // This typically means attendeeEmail should match req.user.email
    // For this hackathon, we're using req.userId directly as email for simplicity
    if (req.userId.toString() !== attendeeEmail.toString()) {
        res.status(403);
        throw new Error('Not authorized to update status for this attendee.');
    }

    const attendeeIndex = event.attendees.findIndex(att => att.email === attendeeEmail);

    if (attendeeIndex === -1) {
        res.status(404);
        throw new Error('Attendee not found in this event.');
    }

    // Update status in our database
    event.attendees[attendeeIndex].status = status;

    // If the event is from an external source, update there too
    if (event.sourceType !== 'custom' && event.externalEventId) {
        const targetAccount = await ExternalCalendarAccount.findById(event.externalCalendarAccountId);
        if (targetAccount) {
            const accessToken = decrypt(targetAccount.accessToken);
            if (targetAccount.calendarType === 'google') {
                googleOAuth2Client.setCredentials({ access_token: accessToken });
                const calendarService = google.calendar({ version: 'v3', auth: googleOAuth2Client });

                // Google's API requires fetching the event, modifying attendee status, and then patching
                const googleEventResponse = await calendarService.events.get({
                    calendarId: targetAccount.externalCalendarId,
                    eventId: event.externalEventId,
                });
                const googleEvent = googleEventResponse.data;

                const googleAttendee = googleEvent.attendees?.find(att => att.email === attendeeEmail);
                if (googleAttendee) {
                    googleAttendee.responseStatus = status; // 'accepted', 'declined', 'needsAction'
                }

                await calendarService.events.patch({
                    calendarId: targetAccount.externalCalendarId,
                    eventId: event.externalEventId,
                    resource: { attendees: googleEvent.attendees }, // Only send attendees for update
                });

            }
            // Commented out Outlook attendee status update logic
            /*
            else if (targetAccount.calendarType === 'outlook') {
                const graphClient = Client.init({
                    authProvider: (done) => {
                        done(null, accessToken);
                    },
                });

                // Outlook's API has a direct way to respond to an event
                // This assumes the attendeeEmail is the current user's email
                let outlookStatus;
                switch (status) {
                    case 'accepted':
                        outlookStatus = 'Accepted';
                        break;
                    case 'declined':
                        outlookStatus = 'Declined';
                        break;
                    case 'pending':
                    default:
                        outlookStatus = 'TentativelyAccepted'; // Outlook doesn't have a direct 'pending' response
                        break;
                }

                // Call the appropriate action endpoint based on the status
                if (outlookStatus === 'Accepted') {
                    await graphClient.api(`/me/events/${event.externalEventId}/accept`).post({
                        sendResponse: true, // Send a response email to the organizer
                        comment: `Responding Accepted via Unified Calendar.`,
                    });
                } else if (outlookStatus === 'Declined') {
                    await graphClient.api(`/me/events/${event.externalEventId}/decline`).post({
                        sendResponse: true,
                        comment: `Responding Declined via Unified Calendar.`,
                    });
                } else { // TentativelyAccepted or other pending states
                     await graphClient.api(`/me/events/${event.externalEventId}/tentativelyAccept`).post({
                        sendResponse: true,
                        comment: `Responding Tentatively Accepted via Unified Calendar.`,
                    });
                }
            }
            */
        }
    }

    await event.save();
    res.json({ message: 'Attendee status updated successfully', event });
});


// Export sync function for cron job
module.exports = {
    connectCalendar,
    googleCallback,
    // outlookCallback, // Commented out
    getCalendarAccounts,
    refreshCalendar,
    createEvent,
    getEvents,
    updateEvent,
    deleteEvent,
    updateAttendeeStatus,
    syncExternalCalendar, // Exported for cron job to use
};
