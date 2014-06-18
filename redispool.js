
//var poolModule= require("generic-pool")
//var poolModule= require("./generic-pool.js");
var poolModule = require("./pool.js");
var redis = require("redis");



var RedisPool = poolModule.Pool({
      name: "redis",
      create: function(callback) {
        var cachedClient = redis.createClient();

        cachedClient.on("error", function(err) {
          return console.log(err+"client error during process ");
        });
        return callback(null, cachedClient);
      },
      destroy: function(cachedClient) {
        return cachedClient.end();
      },
      idleTimeoutMillis: 30000,
      log: false,
      max: 10,
      min: 0
});


module.exports = RedisPool;

