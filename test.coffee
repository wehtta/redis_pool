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
    cachedClient.on "error", (err)->
      console.log "error during process" + err
    callback null, cachedClient
  destroy:()->
    cachedClient.end()
  idleTimeoutMillis: 3000
  log:false
  max:10
  min:0

describe "test pool ", ()->
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
      mockClient.set.calledOnce.should.ok
      redis.createClient.restore()
      # redis.createClient.calledOnce.should.ok
      result.should.equal "OK"
      done()

  it "test pool create err", (done)->
    sinon.stub factory, "create", (callback)-> 
      callback new Error("create error"), null
    RedisPool = Pool.Pool factory
    RedisPool.acquire (err, result)->
      err.should.eql new Error("create error")
      factory.create.restore()
      done()

  it "test pool destroy", (done)->
    desCount=0
    factory.idleTimeoutMillis = 100
    sinon.stub factory , "destroy", ()-> ++desCount
    RedisPool = Pool.Pool factory
    spy = sinon.spy factory, "create"

    RedisPool.acquire (err, client)->
      RedisPool.release client

    setTimeout ()-> 
      desCount.should.equal 1
      spy.calledOnce.should.ok
      factory.create.restore()
      factory.destroy.restore()
      done()
    , 100

  it "ensure the minimal", (done)->
    factory.min = 3
    spy = sinon.spy factory, "create"

    RedisPool = Pool.Pool factory

    setTimeout ()->
      spy.callCount.should.equal 3
      factory.create.restore()
      done()
    , 100

  it "test available during idleTimeoutMillis", (done)->
    factory.min =3
    spy = sinon.spy factory, "destroy"
    RedisPool = Pool.Pool factory

    setTimeout ()->
      spy.callCount.should.equal 0
      factory.destroy.restore()
      done()
    ,100

  it "test limit to factory.max", (done)->
    factory.max =10
    spy = sinon.spy factory, "create"
    RedisPool = Pool.Pool factory

    for i in [1..12]
      RedisPool.acquire (err, client)->
        RedisPool.release client

    setTimeout ()->
      spy.callCount.should.equal 10
      factory.create.restore()
      done()
    ,100

  it  "test get client when client release", (done)->
    factory.max = 10
    clientid = 0

    factory.create = (callback)->
      callback null, ++clientid
    spy = sinon.spy factory , "create"
    RedisPool = Pool.Pool factory

    for i in [1..10]
      RedisPool.acquire (err, client)->
        if client == 9
          setTimeout RedisPool.release client , 50  

    RedisPool.acquire (err, clientid)->
      spy.callCount.should.equal 10
      clientid.should.equal 9
      factory.create.restore()
      done()




