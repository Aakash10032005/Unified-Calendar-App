const mongoose = require('mongoose');
require('dotenv').config(); // Load environment variables

const connectDB = async () => {
    try {
        console.log('Attempting to connect to MongoDB...');
        // Log the URI being used (for debugging only, be careful with sensitive info)
        console.log(`MONGO_URI: ${process.env.MONGO_URI}`); // <-- UNCOMMENTED THIS LINE

        const conn = await mongoose.connect(process.env.MONGO_URI, {
            // These options are often not needed in recent Mongoose versions (6.0+),
            // but including them for compatibility if you're on an older setup or for clarity.
            // useNewUrlParser: true,
            // useUnifiedTopology: true,
            // useCreateIndex: true, // Not needed in Mongoose 6+
            // useFindAndModify: false, // Not needed in Mongoose 6+
        });
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`MongoDB Connection Error: ${error.message}`);
        console.error(`Please check your MONGO_URI in the .env file.`);
        // process.exit(1); // <-- TEMPORARILY COMMENTED OUT THIS LINE
    }
};

module.exports = connectDB;
