.PHONY: all build clean install uninstall

all: build

bin/logburn: src/** config/**
	shards build

build: bin/logburn

clean:
	rm -rf lib
	rm -rf bin

install: build
	install ./bin/logburn -o root -m 755 /usr/bin/

uninstall: 
	rm /usr/bin/logburn
