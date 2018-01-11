build/hello_world: build .deps *.pony
	stable env ponyc -o build --debug

.deps: bundle.json
	stable fetch

build:
	mkdir build

run: build/hello_world
	build/hello_world

clean:
	rm -rf .deps
	rm -rf build

.PHONY: clean run
