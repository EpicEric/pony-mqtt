build/mqtt: build mqtt/*.pony mqtt/test/*.pony
	ponyc mqtt/test -o build -b mqtt --debug

build:
	mkdir build

test: build/mqtt
	build/mqtt

clean:
	rm -rf build

.PHONY: clean test
