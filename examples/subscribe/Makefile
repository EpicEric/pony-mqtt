build/subscribe: build .deps *.pony
	stable env ponyc -o build --debug

.deps: bundle.json
	stable fetch

build:
	mkdir build

run: build/subscribe
	build/subscribe

clean:
	rm -rf .deps
	rm -rf build

.PHONY: clean run
