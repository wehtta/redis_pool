should = require "should"
#RedisPool = require "./redispool.js"
sinon = require "sinon"
Pool= require "../lib/pool.js"
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

RedisPool = Pool.Pool factory

describe "test RedisPool now", ()->

  beforeEach ()->
    RedisPool.execcmd "flushdb", (err, result)->
      if err
        console.log "flushdb error"

  it "test redisRedisPool hmset cmd", (done)->
    RedisPool.execcmd "hmset" ,"student", "name", "Jim", "location", "beijing", (err, result)->
      if err
        done err
      else
        console.log result
        result.should.equal "OK"
        RedisPool.execcmd "hgetall", "student", (err, res)->
          if err 
            done err
          else
            console.log res
            res.should.eql {"name": "Jim", "location": "beijing"}
            done()

  it "test redisRedisPool rename", (done)->
    RedisPool.execcmd "set", "hainan", "haikou", (err, result)->
      if err
        done err
      else
        RedisPool.execcmd "rename", "hainan", "renamekey", (err, result)->
          if err
            done err
          else
            result.should.equal "OK"
            RedisPool.execcmd  "get", "renamekey", (err, res)->
              if err
                done err
              else
                console.log res
                res.should.equal "haikou"
              done()


  it "test redisRedisPool hdel", (done) ->
    RedisPool.execcmd "hmset", "student", "name", "Jim", "location", "beijing", (err, result)->
      if err
        done err
      else

        RedisPool.execcmd "hdel", "student", "location", "beijing", (err, result) ->
          if err
            done err
          else
            RedisPool.execcmd "hgetall", "student", (err, res) ->
              if err
                done err
              else
                res.should.eql {"name": "Jim"}
                done()

  it "test redisRedisPool push and pop", (done)->
    RedisPool.execcmd "lpush", "city", "shanghai", "beijing", (err, result)->
      if err
        done err
      else
        RedisPool.execcmd "rpop", "city", (err, res)->
          if err
            done err
          else
            res.should.equal "shanghai"
            done()