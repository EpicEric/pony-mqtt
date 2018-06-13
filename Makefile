DOCS_DIR=mqtt-docs

build/mqtt: build mqtt/*.pony mqtt/test/*.pony
	ponyc mqtt/test --output build --bin-name mqtt --debug

build:
	mkdir build

test: build/mqtt
	build/mqtt

docs: mkdocs.yml mqtt/*.pony
	rm -rf mqtt-docs
	ponyc mqtt --docs --pass docs

mqtt-docs: docs

docs-online:
	if [ ! -d "$(DOCS_DIR)" ]; then make docs; fi
	python fix_docs.py -d mqtt-docs -t mkdocs.yml

clean:
	rm -rf build
	rm -rf mqtt-docs

.PHONY: clean docs docs-online test
