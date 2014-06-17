should = require "should"
RedisPool = require "./redispool.js"
sinon = require "sinon"
Pool= require "./pool.js"

describe "function behaviour test",()->
	it "unit test RedisPool.acquire", (done)->
		spy = sinon.spy RedisPool, "acquire"
		spy1 = sinon.spy RedisPool, "release"
		spy2 = sinon.spy RedisPool, "destroy"

		RedisPool.execcmd "flushdb", (err, result)->
			if err
				done err
			else	
				spy.calledOnce.should.equal true
				spy1.called.should.equal true
				#spy2.called.should.equal true	//a period timeout
				done()

describe "client pool test ", ()->
	it "test the ensure minimum", (done)->
		createCounter = 0
		destroyCounter = 0
		factory = 
			name: "redis"
			create : (callback)->
    	  		callback null, ++createCounter 
    	  	destroy : (callback)->
    	  		callback null, ++destroyCounter
   	
    	  	idleTimeoutMillis: 30000
    	  	log: false
    	  	max: 10
    	  	min: 3
	
		testPool = Pool.Pool factory
		createCounter.should.equal 3
		done()

	it "test the limit to maximum", (done)->
		createCounter = 0
		destroyCounter = 0
		factory = 
			name: "redis"
			create : (callback)->
    	  		callback null, ++createCounter 
    	  	destroy : ()->
    	  		callback null, ++destroyCounter
   	
    	  	idleTimeoutMillis: 3000
    	  	log: false
    	  	max: 10
    	  	min: 3

		testPool = Pool.Pool factory
		
		for i in [1..20]
    		res = testPool.acquire (err, counter) ->
    			typeof counter == "number"

    		console.log res
    		if !res
    			testPool.count.should.equal 11
    			break;	
    	done()
    			

    

describe "test RedisRedisPool" ,()->
	before (done)->
		RedisPool.execcmd "flushdb", (err, result)->
			if err
				done err
			else
				console.log "clear redis data"
				result.should.equal "OK"
				done()


	it "test redis set cmd and renamecmd", (done)->
		RedisPool.execcmd "set", "hainan", "haikou",  (err, result)->
			if err
				done err
			else
				result.should.equal "OK"
				done()

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
