should = require "should"
#RedisPool = require "./redispool.js"
sinon = require "sinon"
Pool= require "./pool.js"
eventEmitter = require('events').EventEmitter
redis = require 'redis'

factory =
  name: "redis"
  create: (callback)->
    cachedClient = redis.createClient()
    console.log cachedClient.toString()
    console.log "******"+cachedClient+"*******"
    cachedClient.on "error", (err)->
      console.log "error during process" + err
    callback null, cachedClient
  destroy:()->
    cachedClient.end()
  idleTimeoutMillis: 3000
  log:false
  max:10
  min:0

describe "test pool create", ()->
  it "test pool create", (done)->
    mockClient = 
      name: "mockclient"
    mockClient = new eventEmitter()
    sinon.stub redis, "createClient", ()-> mockClient
    mockClient.set = sinon.spy  (args, callback)->
      console.log args
      callback null, "OK"
  
    RedisPool = Pool.Pool factory
    RedisPool.execcmd "set", "testkey", "testvalue", (err, result)->
      console.log err
      console.log result
      # redis.createClient.calledOnce.should.ok
      result.should.equal "OK"
      done()


#       create: function(callback) {
#         var cachedClient = redis.createClient();

#         cachedClient.on("error", function(err) {
#           return console.log(err+"client error during process ");
#         });
#         return callback(null, cachedClient);
#       },
#       destroy: function(cachedClient) {
#         return cachedClient.end();
#       },
#       idleTimeoutMillis: 30000,
#       log: false,
#       max: 10,
#       min: 0

# RedisPool = Pool.Pool 

# describe "function behaviour test",()->
#   it "unit test RedisPool.acquire", (done)->
#     spy = sinon.spy RedisPool, "acquire"
#     spy1 = sinon.spy RedisPool, "release"
#     spy2 = sinon.spy RedisPool, "destroy"

#     RedisPool.execcmd "flushdb", (err, result)->
#       if err
#         done err
#       else  
#         spy.calledOnce.should.equal true
#         spy1.called.should.equal true
#         #spy2.called.should.equal true  //a period timeout
#         done()

# describe "client pool test ", ()->
#   it "test the ensure minimum", (done)->
#     createCounter = 0
#     factory = 
#       name: "redis"
#       create : (callback)->callback null, ++createCounter 

#       idleTimeoutMillis: 30000
#       log: false
#       max: 10
#       min: 3
  
#     testPool = Pool.Pool factory
#     createCounter.should.equal 3
#     done()

#   it "test the limit to maximum", (done)->
#     createCounter = 0
#     factory = 
#       name: "redis"
#       create : (callback)->
#         callback null, ++createCounter 
#       destroy : ()->

#       idleTimeoutMillis: 3000
#       log: false
#       max: 10
#       min: 3

#     testPool = Pool.Pool factory
    
#     for i in [1..20]
#       res = testPool.acquire (err, counter) ->
#         typeof counter == "number"  
#       console.log res
#       if !res
#         testPool.getCount().should.equal 10
#         break 
#     done()

#   it "test availableobject  on create", (done)->
#     process.on "uncaughtException" ,(err)->
#       console.log err
#       process.exit 1
#     clientid =0
#     destroyid = []
#     factory =
#       name : "redis"
#       create: (callback) -> callback(null, ++clientid)
#       destroy: (id) -> destroyid.push id
#       idleTimeoutMillis: 100
#       max: 10
#       min: 2

#     testPool = Pool.Pool factory
#     testPool.acquire (err, client)-> #process.nextTick, here get createid =3
#       testPool.getAvailableObjects().length.should.equal 1
#       done()

#   it "test client should be available during idleTimeoutMillis" ,(done)->
#     clientid = 0
#     factory =
#       name: "redis"
#       create: (callback)-> callback(null, ++clientid)
#       destroy:()->
#       idleTimeoutMills: 100
#       max: 10
#       min: 1

#     testPool = Pool.Pool factory
#     testPool.acquire (err, client)->
#       setTimeout testPool.release client, 5 #push the client into availableobj

#     testPool.acquire (err, client) ->
#       if typeof client == "number"
#         client.should.equal 1
#         testPool.release client
#         done()

#   it "test waitingclient should be right when get factory.max", (done)->
#     clientid = 0
#     factory = 
#       name: "redis"
#       create: (callback) -> callback(null, ++clientid)
#       destroy: ()->
#       idleTimeoutMillis: 100
#       max: 5
#       min: 1
#     testPool = Pool.Pool factory
#     for i in [1..5]
#       testPool.acquire (err, client)->
#         #console.log client
#         #no release here, reach factory.max
#     testPool.acquire (err, client)->
#       setTimeout testPool.release client, 5

#     testPool.getWaitingClients().size().should.equal 1
#     done()

#   it "test waitingclient should decrease when there is availableobj", (done)->
#     clientid = 0
#     factory = 
#       name: "redis"
#       create: (callback) -> callback(null, ++clientid)
#       destroy: (id)-> console.log "destroyid"
#       idleTimeoutMillis: 100
#       max: 5
#       min: 1
#     testPool = Pool.Pool factory
#     for i in [1..5]
#       testPool.acquire (err, client)->
#         console.log client
#         setTimeout testPool.release client , 50
#         #console.log client
#         #no release here, reach factory.max
#     setTimeout ()->
#       testPool.acquire (err, client)->
#       #here should assign the waitclient with avaiableobj
#       testPool.getWaitingClients().size().should.equal 0
#       done()
#     , 110

# describe.only "test RedisRedisPool" ,()->
#   # before (done)->
#   #   RedisPool.execcmd "flushdb", (err, result)->
#   #     if err
#   #       done err
#   #     else
#   #       console.log "clear redis data"
#   #       result.should.equal "OK"
#   #       done()
#   mockClient = {}

#   before ->
#     sinon.stub redis, 'createClient', -> mockClient

#   after  ->
#     redis.createClient.restore()

#   it "test redis set cmd and renamecmd", (done)->
#     mockClient = new eventEmitter()
#     # mockClient = {name:'superwolf'}
#     mockClient.set = sinon.spy ([state, city], callback)-> 
#       console.log arguments
#       callback(null, "OK")

    
#     RedisPool.execcmd "set", "hainan", "haikou",  (err, result)->
#       console.log arguments
#       if err
#         throw err
#       else
#         result.should.equal "OK"
#         redis.createClient.calledOnce.should.ok
#         mockClient.set.calledOnce.should.ok
#         done()

#   it "test redis error", (done)->
#     mockClient = new eventEmitter()
#     # mockClient = {name:'superwolf'}
    
#     mockClient.on "error", (err)->
#       console.log err
#       done()
#     mockClient.emit 'error'
    
    

  # it "test redisRedisPool hmset cmd", (done)->
  #   RedisPool.execcmd "hmset" ,"student", "name", "Jim", "location", "beijing", (err, result)->
  #     if err
  #       done err
  #     else
  #       console.log result
  #       result.should.equal "OK"
  #       RedisPool.execcmd "hgetall", "student", (err, res)->
  #         if err 
  #           done err
  #         else
  #           console.log res
  #           res.should.eql {"name": "Jim", "location": "beijing"}
  #           done()

  # it "test redisRedisPool rename", (done)->
  #   RedisPool.execcmd "rename", "hainan", "renamekey", (err, result)->
  #     if err
  #       done err
  #     else
  #       result.should.equal "OK"
  #       RedisPool.execcmd  "get", "renamekey", (err, res)->
  #         if err
  #           done err
  #         else
  #           console.log res
  #           res.should.equal "haikou"
  #           done()


  # it "test redisRedisPool hdel", (done) ->
  #   RedisPool.execcmd "hdel", "student", "location", "beijing", (err, result) ->
  #     if err
  #       done err
  #     else
  #       RedisPool.execcmd "hgetall", "student", (err, res) ->
  #         if err
  #           done err
  #         else
  #           res.should.eql {"name": "Jim"}
  #           done()

  # it "test redisRedisPool push and pop", (done)->
  #   RedisPool.execcmd "lpush", "city", "shanghai", "beijing", (err, result)->
  #     if err
  #       done err
  #     else
  #       RedisPool.execcmd "rpop", "city", (err, res)->
  #         if err
  #           done err
  #         else
  #           res.should.equal "shanghai"
  #           done()
