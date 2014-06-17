should = require "should"
Pool = require "./redispool.js"
sinon = require "sinon"

describe "function behaviour test",()->
	it "unit test Pool.acquire", (done)->
		spy = sinon.spy Pool, "acquire"
		spy1 = sinon.spy Pool, "release"
		spy2 = sinon.spy Pool, "destroy"

		Pool.execcmd "flushdb", (err, result)->
			if err
				done err
			else	
				spy.calledOnce.should.equal true
				spy1.called.should.equal true
				#spy2.called.should.equal true	//a period timeout
				done()


describe "test RedisPool" ,()->
	before (done)->
		Pool.execcmd "flushdb", (err, result)->
			if err
				done err
			else
				console.log "clear redis data"
				result.should.equal "OK"
				done()


	it "test redis set cmd and renamecmd", (done)->
		Pool.execcmd "set", "hainan", "haikou",  (err, result)->
			if err
				done err
			else
				result.should.equal "OK"
				done()

	it "test redispool hmset cmd", (done)->
		Pool.execcmd "hmset" ,"student", "name", "Jim", "location", "beijing", (err, result)->
			if err
				done err
			else
				console.log result
				result.should.equal "OK"
				Pool.execcmd "hgetall", "student", (err, res)->
					if err 
						done err
					else
						console.log res
						res.should.eql {"name": "Jim", "location": "beijing"}
						done()

	it "test redispool rename", (done)->
		Pool.execcmd "rename", "hainan", "renamekey", (err, result)->
			if err
				done err
			else
				result.should.equal "OK"
				Pool.execcmd  "get", "renamekey", (err, res)->
					if err
						done err
					else
						console.log res
						res.should.equal "haikou"
						done()


	it "test redispool hdel", (done) ->
		Pool.execcmd "hdel", "student", "location", "beijing", (err, result) ->
			if err
				done err
			else
				Pool.execcmd "hgetall", "student", (err, res) ->
					if err
						done err
					else
						res.should.eql {"name": "Jim"}
						done()

	it "test redispool push and pop", (done)->
		Pool.execcmd "lpush", "city", "shanghai", "beijing", (err, result)->
			if err
				done err
			else
				Pool.execcmd "rpop", "city", (err, res)->
					if err
						done err
					else
						res.should.equal "shanghai"
						done()
