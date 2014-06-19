TIMEOUT = 5000
SLOW = 500
MOCHA_OPTS = --compilers coffee:coffee-script/register --timeout $(TIMEOUT) --slow $(SLOW)
TESTS = $(shell find ./test/* -name "*.test.js")
INTEGRATIONS = $(shell find ./test/* -name "*.integration.js")
ALL = $(shell find ./test/* -name "*.js")

testpool:
	@mocha \
		--reporter spec \
		$(MOCHA_OPTS) \
		./test/test.coffee

testredis:
	@mocha \
		--reporter spec \
		$(MOCHA_OPTS) \
		./test/testRedisPool.coffee

test:
	@mocha \
		--reporter spec \
		$(MOCHA_OPTS) \
		./test/*.coffee
