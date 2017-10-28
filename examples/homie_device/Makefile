build/homie_device: build .deps *.pony
	stable env ponyc -o build --debug

.deps: bundle.json *.pony
	rm -rf .deps
	stable fetch

build:
	mkdir build

clean:
	rm -rf .deps
	rm -rf build

.PHONY: clean
