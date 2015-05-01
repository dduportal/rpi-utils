.PHONY: build start backup stop clean

build:
	docker-compose build

start: build
	docker-compose up -d

backup:
	docker-compose run -T backup sh -x /backup.sh

stop:
	docker-compose stop || docker-compose kill

clean: stop
	docker-compose rm -v -f
