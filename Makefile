test:
	./node_modules/.bin/mocha \
		-r coffee-script \
		--reporter nyan \
		test/*.coffee


.PHONY: test
