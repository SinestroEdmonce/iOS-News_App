let router = require("./router");
let server = require("./server");

// Overload the "format" function in string prototype 
String.prototype.format= function(){
    // Transform into the array
    var args = Array.prototype.slice.call(arguments);
    var count = 0;
    // Replace all "{}"
    return this.replace(/\{\}/g, function(item, index){
        return args[count++];
    });
}

// Start the express server
server.start(router);