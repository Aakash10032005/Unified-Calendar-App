const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const bodyParser = require('body-parser');
const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const calendarRoutes = require('./routes/calendarRoutes');
const cron = require('node-cron');
const ExternalCalendarAccount = require('./models/ExternalCalendarAccount');
const { syncExternalCalendar } = require('./controllers/calendarController'); // Import sync function
const { notFound, errorHandler } = require('./middleware/errorMiddleware'); // Basic error handling

// Load environment variables as early as possible
dotenv.config();

// Define PORT early
const PORT = process.env.PORT || 3000;

// Async function to start the entire server application
const startServer = async () => {
    try {
        // 1. Connect to MongoDB
        console.log('Server: Attempting to connect to MongoDB...');
        await connectDB(); // Await the database connection
        console.log('Server: MongoDB connected successfully.');

        // 2. Initialize Express app
        console.log('Server: Initializing Express app...');
        const app = express();

        // 3. Apply general middleware
        console.log('Server: Applying middleware...');
        app.use(cors());
        app.use(bodyParser.json());
        app.use(bodyParser.urlencoded({ extended: true }));
        console.log('Server: Middleware applied.');

        // 4. Define Health Check Endpoint
        console.log('Server: Setting up health check endpoint...');
        app.get('/', (req, res) => {
            res.send('Unified Calendar API is running...');
        });
        console.log('Server: Health check endpoint set.');

        // 5. Define API Routes
        console.log('Server: Setting up API routes...');
        // Verify routes before using them (extra safety check)
        if (!authRoutes || typeof authRoutes !== 'function') throw new Error('authRoutes is not a valid Express Router');
        if (!calendarRoutes || typeof calendarRoutes !== 'function') throw new Error('calendarRoutes is not a valid Express Router');
        
        app.use('/api/auth', authRoutes);
        app.use('/api/calendars', calendarRoutes);
        app.use('/api/events', calendarRoutes);
        console.log('Server: API routes set.');

        // 6. Schedule Cron Job
        console.log('Server: Scheduling cron job...');
        cron.schedule('*/15 * * * *', async () => {
            console.log('Cron: Running scheduled calendar sync...');
            try {
                const activeAccounts = await ExternalCalendarAccount.find({
                    calendarType: { $in: ['google'/*, 'outlook'*/] }
                });
                for (const account of activeAccounts) {
                    console.log(`Cron: Syncing events for account: ${account.accountName} (${account.calendarType})`);
                    await syncExternalCalendar(account._id, account.userId);
                }
                console.log('Cron: Scheduled calendar sync completed.');
            } catch (error) {
                console.error('Cron: Error during scheduled calendar sync:', error);
            }
        });
        console.log('Server: Cron job scheduled.');

        // 7. Apply error handling middleware (must be last)
        console.log('Server: Applying error handling middleware...');
        // Verify error handlers before using them
        if (typeof notFound !== 'function') throw new Error('notFound middleware is not a valid function');
        if (typeof errorHandler !== 'function') throw new Error('errorHandler middleware is not a valid function');

        app.use(notFound);
        app.use(errorHandler);
        console.log('Server: Error handling middleware applied.');

        // 8. Start listening for requests
        app.listen(PORT, () => {
            console.log(`Server: listening on port ${PORT}`);
        });
    } catch (error) {
        console.error(`Server: Fatal startup error: ${error.message}`);
        // Log the stack trace if not in production to help debug
        if (process.env.NODE_ENV !== 'production') {
            console.error(error.stack);
        }
        process.exit(1); // Exit process with failure code
    }
};

// Start the server application
startServer();
