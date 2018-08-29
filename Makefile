PACKAGE=mqtt
BUILD_DIR=build
DOCS_DIR=$(PACKAGE)-docs
TEST_BINARY=$(BUILD_DIR)/$(PACKAGE)

$(TEST_BINARY): $(BUILD_DIR) $(PACKAGE)/*.pony $(PACKAGE)/test/*.pony
	ponyc $(PACKAGE)/test --output $(BUILD_DIR) --bin-name $(PACKAGE) --debug

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

test: $(TEST_BINARY)
	$(TEST_BINARY)

docs: $(DOCS_DIR)

$(DOCS_DIR): mkdocs.yml $(PACKAGE)/*.pony
	rm -rf $(DOCS_DIR)
	ponyc $(PACKAGE) --docs --pass docs

docs-online: | $(DOCS_DIR)
	./fix_docs.py -d $(DOCS_DIR) -t mkdocs.yml

clean:
	rm -rf $(BUILD_DIR) $(DOCS_DIR)

.PHONY: clean docs docs-online test
