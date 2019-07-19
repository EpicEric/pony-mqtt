ifeq (,$(filter $(MAKECMDGOALS),clean))
  ifeq ($(ssl), 1.1.x)
	  SSL = -Dopenssl_1.1.x
  else ifeq ($(ssl), 0.9.0)
	  SSL = -Dopenssl_0.9.0
  else
    $(error Unknown SSL version "$(ssl)". Must set using 'ssl=FOO')
  endif
endif

build/tls: build .deps *.pony
	stable env ponyc ${SSL} -o build --debug

.deps: bundle.json
	stable fetch

build:
	mkdir build

run: build/tls
	build/tls

clean:
	rm -rf .deps
	rm -rf build

.PHONY: clean run
