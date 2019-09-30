all: spec build

build:
	shards build

clean:
	rm -rf lib
	rm -rf bin

install: build
	install ./bin/logburn -o root -m 755 /usr/bin/

uninstall: 
	rm /usr/bin/logburn

spec:
	crystal tool format
