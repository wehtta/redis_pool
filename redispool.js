
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
     // max: config.maxRedisConnection,
     // min: config.minRedisConnection,
      idleTimeoutMillis: 30000,
      log: false
});


RedisPool.execcmd("set", "key34", "value1", function(err, result){
  if(err)
    console.log ("execcmd error");
  else
    RedisPool.execcmd("get", "key34", function(err, res){
        if( err)
            console.log("get value error");
        else
            console.log("successfully"+res);
    });
});

//RedisPool.execcmd("hset", "hashkey", "location", "beijing", function(err, result){
//  if(err)
//    console.log ("execcmd error");
//  else
//    console.log("successfully"+result);
//});

RedisPool.execcmd("get", "key34", function(err, result){
   if(err)
     console.log("exccmd get error");
   else
     console.log("In redis the key2's value is "+result);
});





// RedisPool.setcmd = function(){
//   console.log(arguments);
// // return function() {
//   console.log(arguments);
//    var args, argsLength;
//    args = Array.prototype.slice.call(arguments);
//    console.log(args);

//    argsLength = args.length;
//    var hasCallback = typeof args[argsLength-1] == "function" ? true: false;
 
//    console.log(argsLength);
//    console.log(hasCallback);
//    /******************************************************************************/
//    return RedisPool.acquire(function(err, client){
//      if(err){
//        return hascallback? args[argsLength-1]: console.log("acquire client err");
//      }
//      else{
//           var prevcallback;
//          if(! hasCallback)
//           prevcallback=function(){};
        
//         else
//           prevcallback = args[argsLength-1];

//         args.pop();
//         console.log(args);
        
//           client.set(args, function(err, result){
//             if(err)
//               console.log("client set error")&&prevcallback(err, null);

//             else{
//               console.log(result);
//               console.log("begin to release the client");
//               RedisPool.release(client);
//               prevcallback(null, result);
              
//             }
              
//           });     
          
//         }
//    /*****************************the above codes works totally ok********************************************/
//    else{
//     console.log(hasCallback);
//     var lastarg = args[args.length - 1];
//         var prevcallback, callback;
//         if(hasCallback)
//           prevcallback = lastarg;
//         else{
//           prevcallback = function(){};
//           args.push(prevcallback);
//           }

//         callback= function(){

//           RedisPool.release(client);
//           return prevcallback.apply(null, arguments);
//         };

//         if(hasCallback)
//           args[args.length-1] = callback;
//         if(args.length == 0)
//           args.push(callback);
      
//         console.log(args);
//         client["set"].apply(client,args);
   


//    /**********This bellow code is OK*******************/
//         // var _callback, callback;
//         //   var lastArg = args[args.length - 1];
//         //   var lastArgType = typeof lastArg;
//         //   if (lastArgType === 'function') {
//         //     _callback = lastArg;
//         //   } else if (lastArgType === 'undefined') {
//         //     _callback = function() {};
//         //   } else {
//         //     _callback = function() {};
//         //     args.push(_callback);
//         //   }
//         //   callback = function() {
//         //     RedisPool.release(client);
//         //     console.log("callback called");
//         //     return _callback.apply(null, arguments);
//         //   };
//         //   if (argsLength === 0) {
//         //     args.push(callback);
//         //   } else {
//         //     args[args.length - 1] = callback;
//         //   }
//         //   console.log("lastcallargs" + args);
     
//         //   client["set"].apply(client, args);
//         }

//    });
//  //};
// };

// RedisPool.setcmd("testkey", "testvalue", function(err, result){
//   if(err)
//     console.log("err in redispool set");
//   else
//     console.log(result);
// });