
var poolModule= require("generic-pool");
var redis = require("redis");



var RedisPool = poolModule.Pool({
      name: "redis",
      create: function(callback) {
        var cachedClient = redis.createClient();

        cachedClient.on("error", function(err) {
          return console.log("create client error");
        });
        return callback(null, cachedClient);
      },
      destroy: function(cachedClient) {
        return cachedClient.end();
      },
     // max: config.maxRedisConnection,
     // min: config.minRedisConnection,
      idleTimeoutMillis: 30000,
      log: false,
});

//method test basical RedisPool && acquire func
//RedisPool.acquire(function(err, client){
//  if(err)
//    console.log("error occured in acquire");
//  else{
//    client.set("redis", "database", function(error, result){
//      if(error)
//        console.log("set error");
//      else
//        console.log(result);
//    });
//    RedisPool.release(client);
//    //client[""]
//  }
//});






RedisPool.setcmd = function(){
  console.log(arguments);
// return function() {
  console.log(arguments);
   var args, argsLength;
   args = Array.prototype.slice.call(arguments);
   console.log(args);

   argsLength = args.length;
   var hasCallback = typeof args[argsLength-1] == "function" ? true: false;
 
   console.log(argsLength);
   console.log(hasCallback);
   /******************************************************************************/
   return RedisPool.acquire(function(err, client){
     if(err){
       return hascallback? args[argsLength-1]: console.log("acquire client err");
     }
     // else{
     //      var prevcallback;
     //     if(! hasCallback)
     //      prevcallback=function(){};
        
     //    else
     //      prevcallback = args[argsLength-1];

     //    args.pop();
     //    console.log(args);
        
     //      client.set(args, function(err, result){
     //        if(err)
     //          console.log("client set error")&&prevcallback(err, null);

     //        else{
     //          console.log(result);
     //          RedisPool.release(client);
     //          prevcallback(null, result);
              
     //        }
              
     //      });     
          
     //    }
   /*****************************the above codes works totally ok********************************************/
   else{
        var prevcallback = hasCallback? args[argsLength-1]:(function(){});
        var callback= function(){
          RedisPool.realease(client);
          return prevcallback.apply(null, arguments);
        };

        if(hasCallback)
          args.pop();
      
        console.log(args);
        client["set"].call(client,args,prevcallback);
   }
       //  console.log("successful acquire client");
       // var cmdcallback = hasCallback? args[argsLength-1] : (function(){});
       // var callback= function(){
       //   pool.realease(client);
       //   return cmdcallback.apply(null, arguments);
       // };
       // if(hasCallback)
       //   args[argsLength-1] = callback;
       // else
       //   args.push(callback);
       
       // return client.set.apply(client, args);
     //}

   });
 //};
};

RedisPool.setcmd("ape", "obs", function(err, result){
  if(err)
    console.log("err in redispool set");
  else
    console.log(result);
});