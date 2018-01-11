build/homie_device: build .deps *.pony lib/libffi-sensor.so
	stable env ponyc -o build --debug

build:
	mkdir build

.deps: bundle.json
	stable fetch

lib:
	mkdir lib

lib/libffi-sensor.so: lib sensor.c
	gcc -c -Wall -Werror -fpic -o lib/sensor.o sensor.c
	gcc -shared -o lib/libffi-sensor.so lib/sensor.o

run: build/homie_device
	build/homie_device

clean:
	rm -rf .deps
	rm -rf build
	rm -rf lib

.PHONY: clean run
