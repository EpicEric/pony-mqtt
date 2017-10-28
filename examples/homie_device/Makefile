build/homie_device: build .deps *.pony libffi-sensor.so
	stable env ponyc -o build --debug

build:
	mkdir build

.deps: bundle.json *.pony
	rm -rf .deps
	stable fetch

libffi-sensor.so: sensor.c
	gcc -c -Wall -Werror -fpic sensor.c
	gcc -shared -o libffi-sensor.so sensor.o

clean:
	rm -rf .deps
	rm -rf build
	rm -f sensor.o
	rm -f libffi-sensor.so

.PHONY: clean
