build/mqtt: build mqtt/*.pony mqtt/test/*.pony
	ponyc mqtt/test --output build --bin-name mqtt --debug

build:
	mkdir build

test: build/mqtt
	build/mqtt

docs: mqtt/*.pony
	rm -rf docs
	ponyc mqtt --output docs --docs --pass docs

clean:
	rm -rf build
	rm -rf docs

.PHONY: clean test
