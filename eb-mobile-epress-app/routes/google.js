// Load third-party libraries
let express = require("express");
let googleTrends = require("google-trends-api");

// Start time
const startDate = new Date("2019-06-01");

/**
 * Function that is used to load the routers for google to the parent router
 * @param {express.Router} router 
 */
function google(router) {
    
    router.get("/api/google-trends", function (request, response) {
        // Debug
        console.log("GET: /api/google-trends?q={}");

        // Get the keyword
        const keyword = request.query.q;

        // Obtain the search trending with the given keyword
        googleTrends.interestOverTime({
                "keyword": keyword, 
                "startTime": startDate
            })
            .then(function(data) {
                // Obtain the timelineData, either empty or full of data
                let timelineData = JSON.parse(data).default.timelineData;

                // Clean the data
                let cleanData = [];
                timelineData.forEach(function (item, index) {
                    cleanData.push({
                        "counter": index,
                        "value": item.value[0]
                    });
                });
                response.status(200).send(JSON.stringify({"status": "ok", "results": cleanData}));
            })
            .catch(function (error) {
                response.status(500).send("Server Internal Error.")
            });

    });

}

module.exports = google;