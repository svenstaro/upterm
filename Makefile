SHELL=/bin/bash -o pipefail

.PHONY: docs build proto client install test vet chart

generate: proto

docs:
	rm -rf docs && mkdir docs
	rm -rf etc && mkdir -p etc/man/man1 && mkdir -p etc/completion
	go run cmd/gendoc/main.go

proto:
	docker run -v `pwd`/server:/defs namely/protoc-all -f server.proto -l go -o .
	docker run -v `pwd`/host/api:/defs namely/protoc-all -f api.proto -l go -o .

build:
	go build -o build/upterm -mod=vendor ./cmd/upterm
	go build -o build/uptermd -mod=vendor ./cmd/uptermd

install:
	go install ./cmd/... 

TAG ?= latest
docker_build:
	docker build -t ghcr.io/owenthereal/upterm/uptermd:$(TAG) -f Dockerfile.uptermd .

docker_push: docker_build
	docker push ghcr.io/owenthereal/upterm/uptermd:$(TAG)

test:
	go test ./... -timeout=120s -coverprofile=c.out -covermode=atomic -mod=vendor -count=1 -race -v

vet:
	docker run --rm -v $$(pwd):/app:z -w /app golangci/golangci-lint:latest golangci-lint run -v
