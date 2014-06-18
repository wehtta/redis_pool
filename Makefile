TIMEOUT = 5000
SLOW = 500
MOCHA_OPTS = --compilers coffee:coffee-script/register --timeout $(TIMEOUT) --slow $(SLOW)
TESTS = $(shell find ./test/* -name "*.test.js")
INTEGRATIONS = $(shell find ./test/* -name "*.integration.js")
ALL = $(shell find ./test/* -name "*.js")

test:
	@mocha \
		--reporter spec \
		$(MOCHA_OPTS) \
		test.coffee