// Load third-party libraries
let express = require("express");
let request = require("request");

// Max amount of news to show
const G_MAX_NUM_SHOWN = 10;
// Default image for guardian news
const G_DEFAULT_IMAGE = "guardian-default-image";
// Section and home api url for guardian
const G_SECTION_API_URL = "https://content.guardianapis.com/search?api-key={}&section={}&show-fields=starRating,headline,thumbnail,short-url&show-blocks=all&page-size=20";
const G_HOME_API_URL = "https://content.guardianapis.com/search?api-key={}&orderby=newest&show-fields=starRating,headline,thumbnail,short-url&show-blocks=all&page-size=20";
// Search api url for guardian
const G_SEARCH_API_URL = "https://content.guardianapis.com/search?q={}&api-key={}&show-fields=starRating,headline,thumbnail,short-url&show-blocks=all&page-size=20";
// Article details api url for guardian
const G_ARTICLE_API_URL = "https://content.guardianapis.com/{}?api-key={}&show-fields=starRating,headline,thumbnail,short-url&show-blocks=all";

/**
 * Function that is used to load the routers for guardian to the parent router
 * @param {String} apikey
 * @param {express.Router} router 
 */
function guardian(apikey, router) {

    // Get the section content for guardian news
    router.get("/G/:section", function (request, response) {
        // Debug
        console.log("GET: /G/:section");

        // Parse the url params
        let section = request.params.section;
        section = (section === "sports")? "sport": section
        
        // Combine all params to form the api url
        const API_URL = (section === "home")? 
                            G_HOME_API_URL.format(apikey): 
                            G_SECTION_API_URL.format(apikey, section);
        getNews(API_URL, function (error, status, data) {
            if (error || status !== 200) {
                return response.status(500).send("Server Internal Error.")
            }

            response.status(200).send(JSON.stringify(data));
        }, "section");
    });
    
    router.get("/G/articles/search", function (request, response) {
        // Debug
        console.log("GET: /G/articles/search?q={}");

        // Parse the url params
        let keyword = request.query.q

        // Combine all params to form the api url
        const API_URL = G_SEARCH_API_URL.format(keyword, apikey);
        getNews(API_URL, function (error, status, data) {
            if (error || status !== 200) {
                return response.status(500).send("Server Internal Error.")
            }

            response.status(200).send(JSON.stringify(data));
        }, "search");
    });

    router.get("/G/details/article", function (request, response) {
        // Debug
        console.log("GET: /G/details/artilce?id={}");

        // Parse the url params
        let articleId = request.query.id;

        // Combine all the params to form the api url
        const API_URL = G_ARTICLE_API_URL.format(articleId, apikey);
        getArticle(API_URL, function (error, status, data) {
            if (error || status != 200) {
                return response.status(500).send("Server Internal Error.");
            }

            response.status(200).send(JSON.stringify(data));
        })
    });

    /**
     * Function that is used to get the section news from the guardian news, using the API
     * @param {*} url 
     * @param {*} callback 
     */
    function getArticle(url, callback) {
        request(url, function(error, response, body) {
            // Http request error 
            if (error) {
                return callback(error, null, null);
            }

            // Pre-process the data
            let rawData = JSON.parse(body).response.content;
            let cleanData = validation(rawData);
            delete cleanData.isValid;

            // Handle the publication time
            cleanData.timeDiff = calculateTimeDifference(cleanData.publishedAt);
            cleanData.publicationDate = transformDateFormat(cleanData.publishedAt);
            callback(null, response.statusCode, {
                "status": "ok", 
                "result": cleanData
            });
        })
    }

    /**
     * Function that is used to get the section news from the guardian news, using the API
     * @param {*} url 
     * @param {*} callback 
     * @param {String} forWhat
     */
    function getNews(url, callback, forWhat) {
        request(url, function(error, response, body) {
            // Http request error 
           if (error) {
               return callback(error, null, null);
           }

           // Pre-process the data
           let rawData = JSON.parse(body).response.results;
           let cleanData = [];
           rawData.forEach(function (item, index) {
                let news = validation(item);
                if (news.isValid) {
                    // Remove the redundant key
                    delete news.isValid;
                    
                    // Handle the publication time
                    news.timeDiff = calculateTimeDifference(news.publishedAt);
                    news.publicationDate = transformDateFormat(news.publishedAt);
                    cleanData.push(news);
                }
           });
           callback(null, response.statusCode, {
               "status": "ok", 
               "results": cleanData.slice(0, G_MAX_NUM_SHOWN)
            });
        })
    }

    /**
     * Function that is used to validate the artilce
     * @param {*} article
     */
    function validation(article) {

        function check(item) {
            return (item === null || item === "" || item === NaN);
        }

        // Pre-store the values
        let assets = (article.blocks.main? (
                article.blocks.main.elements[0].assets? 
                    article.blocks.main.elements[0].assets: []
            ): []
        );
        
        // Obtain description
        let newsDesc = []
        article.blocks.body.forEach(function (item, index) {
            newsDesc.push(item.bodyHtml)
        });

        let ret = {
            "isValid": true,
            "title": article.webTitle,
            "imageURL": (
                (assets.length === 0)? 
                    G_DEFAULT_IMAGE: assets[assets.length-1].file),
            "thumbnail": (
                article.fields? (
                    article.fields.thumbnail? 
                        article.fields.thumbnail: G_DEFAULT_IMAGE
                    ): G_DEFAULT_IMAGE),
            "sectionId": article.sectionName,
            "articleId": article.id,
            "publishedAt": article.webPublicationDate,
            "description": newsDesc.join(""),
            "url": article.webUrl,
        };

        // Validate the values
        Object.keys(ret).forEach(function (key) {
            if (key !== "isValid" && check(ret[key])) {
                // If the image url is invalid, replace it
                if (key === "imageURL" || key === "thumbnail") {
                    ret[key] = G_DEFAULT_IMAGE;
                }
                // Otherwise, the article is invalid
                else {
                    ret.isValid = false;
                }
            }
        });

        return ret;
    }

    /**
     * Function that is used to calculate the time difference between the publication date and the current time 
     * @param {*} publicationTime 
     */
    function calculateTimeDifference(publicationTime) {
        let publishedDate = new Date(publicationTime);
        let currentDate = new Date();

        // Obtain the time difference using milliseconds as the unit
        let timeDiff = currentDate.getTime()-publishedDate.getTime();
        timeDiff = Math.floor(timeDiff/1000);

        // If time difference is smaller than 1 minute
        if (timeDiff < 60) {
            return `${timeDiff}s ago`;
        }
        // If time difference is smaller than 1 hour
        else if (timeDiff < 60*60) {
            return `${Math.floor(timeDiff/60)}m ago`;
        }
        // If time difference is greater than 1 hour
        else {
            return `${Math.floor(timeDiff/(60*60))}h ago`;
        }
    }

    /**
     * Function that is used to transform the current date format yyyy-MM-dd hh:mm:ss to dd MM yyyy
     * @param {*} publicationTime 
     */
    function transformDateFormat(publicationTime) {
        let date = publicationTime.split("T")[0].split("-");

        const MONTH = {
            "01": "Jan", "02": "Feb", "03": "Mar", "04": "Apr",
            "05": "May", "06": "Jun", "07": "Jul", "08": "Aug",
            "09": "Sept", "10": "Oct", "11": "Nov", "12": "Dec"
        }

        let newFormatDate = [date[2], MONTH[date[1]], date[0]];
        return newFormatDate.join(" ");
    }
}

module.exports = guardian;
