build/mqtt: build mqtt/*.pony
	ponyc mqtt -o build --debug

build:
	mkdir build

test: build/mqtt
	build/mqtt

clean:
	rm -rf build

.PHONY: clean test
