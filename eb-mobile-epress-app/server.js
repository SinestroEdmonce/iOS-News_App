// Load the third-party libraries
let express = require("express");
let bodyParser = require("body-parser");

function start(router) {
    // Create a express instance
    let server = express();

    // Body parser setup
    server.use(bodyParser.urlencoded({"extended": false}));
    server.use(bodyParser.json());

    // Load the router
    server.use(router);

    // Configure the listener port
    let port = process.env.PORT || 8000;

    server.listen(port, function () {
        console.log(`Server is running at port ${port}...`);
    });
}

exports.start = start;

