const express = require('express');
const router = express.Router(); // Initialize an Express Router
const { registerUser, loginUser } = require('../controllers/authController'); // Controller functions for auth logic

// @desc    Register a new user
// @route   POST /signup (When mounted under /api/auth in server.js, this becomes /api/auth/signup)
// @access  Public
router.post('/signup', registerUser);

// @desc    Authenticate user & get token
// @route   POST /login (When mounted under /api/auth in server.js, this becomes /api/auth/login)
// @access  Public
router.post('/login', loginUser);

module.exports = router; // Essential: Export the router instance
