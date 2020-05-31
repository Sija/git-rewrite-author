prefix ?= /usr/local/bin

.PHONY: build
build:
	shards build --release

.PHONY: install
install: build
	cp bin/git-rewrite-author $(prefix)

.PHONY: uninstall
uninstall:
	rm $(prefix)/git-rewrite-author
