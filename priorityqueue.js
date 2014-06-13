
//this queue will fetch object according to priority
//decremental priority, first is the most important

var PriorityQueue = function(){

	var prio_array=[]; var size=0;
	enqueue: function(obj, priority){

		var objWithPrio = {"obj": obj, "priority": priority};
		var min=0, max=prio_array.length, mid;

		while(min < max){
			mid =(min + max) /2;
			if(priority > prio_array[mid].priority)
				min = mid + 1;
			if(priority < prio_array[mid].priority)
				max = mid -1;
		}
		prio_array.splice(mid, 0, objWithPrio);
	}
// the queue is incremental, priority decreases
	dequeue: function(){
		var obj = prio_array.shift();
		return obj;
	}
	size : function(){
		return prio_array.length;
	}
}


/*factory should be like
{
    name     : 'redis',
    create   : function(callback) {
        var Client = require('mysql').Client;
        var c = new Client();
        c.user     = 'scott';
        c.password = 'tiger';
        c.database = 'mydb';
        c.connect();

        // parameter order: err, resource
        // new in 1.0.6
        callback(null, c);
    },
    destroy  : function(client) { client.end(); },
    max      : 10,
    // optional. if you set this, make sure to drain() (see step 3)
    min      : 2, 
    // specifies how long a resource can stay idle in pool before being removed
    idleTimeoutMillis : 30000,
     // if true, logs via console.log - can also be a function
    log : true 
}*/
exports.Pool = function(factory){
	var para={},
	this.idleTimeoutMillis = factory.idleTimeoutMillis || 3000,
	this.waitingClients = new PriorityQueue(),
	this.connectCounter = 0,

	this.connectMin = factory.min || 3,
	this.connectMax = factory.max ||10,
	this.create = factory.create;
	ensure_min_connect();

}

Pool.prototype.createResource = function(){
	var obj = this.waitingClients.dequeue();
	factory.create(function(){
		var err = arguments[0],
			client = arguments[1];


		var cmd= obj['cmd'];
		var callback = obj['callback'];
		client.query(cmd, function(err, result){
			callback(err, result);
		});

	})
}

Pool.prototype.ensure_min_connect = function(){
	while(connectCounter < connectMin){
		createResource();
	}
}


Pool.prototype.dispense = function(){
	if( waitingClients.size() > 0){
		if(count < connectMax)
			createResource();

	}


}

// when have created pool, directly exec commands by priority.

RedisPool.prototype.exec = function(cmd){
  return function(){
    var args, argsLength;
    args = Array.prototype.slice.call(arguments);
    argsLength = args.length;
    var hasCallback = typeof args[argsLength-1] == "function" ? true: false;
    return pool.acquire(function(err, client){
      if(err){
        return hascallback? args[argsLength-1]: console.log("acquire client err");
      }
      else{
        var cmdcallback = hasCallback? args[argsLength-1] : (function(){});
        var callback= function(){
          pool.realease(client);
          return cmdcallback;
        }
        if(hasCallback)
          args[argsLength-1] = callback;
        else
          args.push(callback);
        
        return client[cmd](client, args);
      }

    });
  }
}


