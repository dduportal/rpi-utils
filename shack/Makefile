.PHONY: build start backup stop clean set_b2d_pat all

all: clean set_b2d_pat build start

build:
	docker-compose build

start: 
	docker-compose up -d

backup:
	docker-compose run -T backup sh -x /backup.sh

stop:
	docker-compose stop || docker-compose kill

clean: stop
	docker-compose rm -v -f

set_b2d_pat:
	boot2docker halt
	VBoxManage modifyvm "boot2docker-vm" --natpf1 "docker-registry,tcp,,5000,,5000"
	VBoxManage modifyvm "boot2docker-vm" --natpf1 "http-proxy,tcp,,3128,,3128"
	boot2docker up
