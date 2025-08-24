const jwt = require('jsonwebtoken');
const User = require('../models/User'); // Required to find user by ID
require('dotenv').config(); // Load environment variables

// Middleware to protect routes, ensuring only authenticated users can access them.
const protect = async (req, res, next) => {
    let token;

    // Check if Authorization header exists and starts with 'Bearer'
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            // Extract the token from the header (e.g., "Bearer TOKEN")
            token = req.headers.authorization.split(' ')[1];

            // Verify the token using the JWT_SECRET from environment variables
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Find the user by ID from the decoded token payload
            // Attach the user object (excluding password) and userId to the request
            req.user = await User.findById(decoded.id).select('-password');
            req.userId = decoded.id; // Store userId directly for easier access in controllers

            next(); // Proceed to the next middleware or route handler
        } catch (error) {
            console.error('Auth middleware error:', error); // Log the error for debugging
            res.status(401);
            throw new Error('Not authorized, token failed'); // Propagate error for errorHandler
        }
    }

    if (!token) {
        res.status(401);
        throw new Error('Not authorized, no token provided'); // Propagate error for errorHandler
    }
};

module.exports = { protect };
