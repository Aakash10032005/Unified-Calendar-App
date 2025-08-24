Unified Calendar App


🌟 Project Overview
The Unified Calendar App is a mobile application designed to simplify schedule management by integrating multiple external calendar services into a single, cohesive view. In today's busy world, individuals often juggle events across various platforms like Google Calendar, Outlook, and personal local calendars. This fragmentation leads to missed appointments, double-bookings, and a general lack of clarity regarding one's commitments.

Our solution provides a centralized Flutter-based mobile interface that aggregates all your events, allowing you to view, create, update, and delete events seamlessly across different connected services. This enhances productivity, reduces stress, and offers a holistic perspective on your personal and professional life.

✨ Features
Centralized Event View: See all your events from connected external calendars and local app events in one intuitive interface.

Google Calendar Integration: Securely connect your Google Calendar account via OAuth2 for seamless event synchronization.

Event Management (CRUD):

Create Events: Add new events to any connected external calendar or to a dedicated "custom" calendar within the app.

View Event Details: Access comprehensive information for each event, including description, location, and attendees.

Update Events: Modify existing events, with changes synchronizing back to the original external service.

Delete Events: Remove events, which also propagates the deletion to the external calendar if applicable.

Attendee Status Management: Respond to event invitations (accept/decline) directly from the app.

Real-time Syncing: Events are periodically synchronized with external services to keep your calendar up-to-date.

User Authentication: Secure user registration and login with JWT-based authentication.

Responsive UI: A modern, user-friendly mobile interface built with Flutter.

🛠️ Technologies Used
Backend (Node.js/Express)
Node.js: JavaScript runtime environment.

Express.js: Web application framework for building RESTful APIs.

MongoDB Atlas: Cloud-hosted NoSQL database for data storage.

Mongoose: MongoDB object modeling for Node.js.

Google APIs (googleapis): For interacting with Google Calendar API.

google-auth-library: For Google OAuth2 authentication.

bcryptjs: For password hashing and security.

jsonwebtoken: For user authentication (JWT).

dotenv: For managing environment variables.

cors: For enabling Cross-Origin Resource Sharing.

body-parser: Middleware for parsing request bodies.

express-async-handler: Simple middleware for handling exceptions in async Express routes.

node-cron: For scheduling periodic calendar synchronization tasks.

nodemon: Development tool for automatic server restarts.

Frontend (Flutter)
Flutter: UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.

provider: State management solution.

http: For making HTTP requests to the backend API.

table_calendar: A customizable calendar widget.

intl: For date and time formatting.

font_awesome_flutter: For iconic vector graphics.

uuid: For generating unique IDs.

url_launcher: For launching URLs in the browser (for OAuth flow).

shared_preferences: For local storage of authentication tokens.

🚀 Getting Started
Follow these instructions to set up and run the Unified Calendar project locally.

Prerequisites
Node.js (LTS version recommended)

npm (comes with Node.js)

MongoDB Atlas Account (or a local MongoDB instance)

Google Cloud Project (with Google Calendar API enabled and OAuth Consent Screen configured)

Flutter SDK (latest stable version recommended)

A code editor like VS Code

Postman or Insomnia for API testing

1. Backend Setup
Clone the repository:

git clone https://github.com/your-username/unified_calendar_backend.git
cd unified_calendar_backend

Install dependencies:

npm install

Create a .env file:
In the root of your unified_calendar_backend directory, create a file named .env and add the following environment variables:

PORT=3000
MONGO_URI=mongodb+srv://<username>:<password>@cluster0.f23yxan.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0
JWT_SECRET=your_very_long_and_complex_secret_key_for_jwt_do_not_share_this_in_public_repos
GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=YOUR_GOOGLE_CLIENT_SECRET
GOOGLE_REDIRECT_URI=http://localhost:3000/api/calendars/google/callback

Replace <username> and <password> with your MongoDB Atlas database user credentials.

JWT_SECRET should be a long, random string.

GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, and GOOGLE_REDIRECT_URI are obtained from your Google Cloud Project. Ensure http://localhost:3000/api/calendars/google/callback is listed as an authorized redirect URI in your Google Cloud OAuth 2.0 Client ID settings.

Start the backend server:

npm run dev

The server should start on http://localhost:3000. Confirm by visiting http://localhost:3000/ in your browser.

2. Frontend (Flutter) Setup
Navigate to the Flutter project directory:

cd ../unified_calendar_app # Assuming it's in a sibling directory

Install Flutter dependencies:

flutter pub get

Configure Backend URL in Flutter:
Open lib/providers/auth_provider.dart and update the _baseUrl variable:

// For Android Emulator, use 10.0.2.2 instead of localhost
// For web/desktop, 'localhost' is fine
final String _baseUrl = "http://10.0.2.2:3000/api"; // Or "http://localhost:3000/api" for web/desktop

Save the file.

Run the Flutter application:

flutter run

Choose your preferred device (emulator, physical device, or web browser).

🧪 API Endpoints
The backend exposes the following API endpoints. The base URL for all API calls is http://localhost:3000/api.

Authentication Endpoints (/api/auth)
POST /api/auth/signup: Register a new user.

Body: { "email": "string", "password": "string" }

Response: { "_id": "string", "email": "string", "userId": "string", "token": "string" }

POST /api/auth/login: Authenticate user and get a JWT token.

Body: { "email": "string", "password": "string" }

Response: { "_id": "string", "email": "string", "userId": "string", "token": "string" }

Calendar Account Endpoints (/api/calendars)
GET /api/calendars/connect/:calendarType/:userId (Protected): Initiate OAuth2 flow for connecting external calendars (e.g., google). Returns an authUrl.

GET /api/calendars/google/callback: Google OAuth2 callback URI (public, handled by backend).

GET /api/calendars/accounts/:userId (Protected): Get all connected calendar accounts for a user.

POST /api/calendars/refresh/:accountId (Protected): Manually trigger a refresh for a specific calendar account.

Event Endpoints (/api/events)
POST /api/events (Protected): Create a new event.

Body: { "userId": "string", "externalCalendarAccountId": "string", "title": "string", "description": "string", "startTime": "ISO_DATE_STRING", "endTime": "ISO_DATE_STRING", "isAllDay": "boolean", "location": "string", "attendees": [{ "email": "string", "status": "string", "isOrganizer": "boolean" }], "sourceType": "string" }

GET /api/events/:userId (Protected): Get all events for a specific user.

PATCH /api/events/:id (Protected): Update an existing event.

DELETE /api/events/:id (Protected): Delete an event.

PATCH /api/events/:id/attendees (Protected): Update attendee status for an event (e.g., accept/decline).

🤝 Contributing
We welcome contributions to the Unified Calendar project! If you'd like to contribute, please follow these steps:

Fork the repository.

Create a new branch (git checkout -b feature/your-feature-name).

Make your changes and ensure tests pass.

Commit your changes (git commit -m 'Add new feature').

Push to the branch (git push origin feature/your-feature-name).

Create a new Pull Request.

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

