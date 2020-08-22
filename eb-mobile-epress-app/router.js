// Load third-party libraries
let express = require("express");

let guardian = require("./routes/guardian");
let google = require("./routes/google")

// Global constant
const GUARDIAN_API_KEY = "a630fd28-8faa-4630-a131-60d6bdb70953";

// Create a router instance
let router = express.Router();

// Load the news api router to the Router middleware
guardian(GUARDIAN_API_KEY, router);
google(router);

module.exports = router;