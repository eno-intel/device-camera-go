.PHONY: build docker test clean prepare update

#GOOS=linux

GO=CGO_ENABLED=0 GO111MODULE=on go
GOCGO=CGO_ENABLED=1 GO111MODULE=on go

MICROSERVICES=cmd/device-camera
.PHONY: $(MICROSERVICES)

VERSION=$(shell cat ./VERSION 2>/dev/null || echo 0.0.0)

GIT_SHA=$(shell git rev-parse HEAD)
GOFLAGS=-ldflags "-X github.com/edgexfoundry/device-camera-go.Version=$(VERSION)"

build: $(MICROSERVICES)

cmd/device-camera:
	go mod tidy
	$(GOCGO) build $(GOFLAGS) -o $@ ./cmd

docker:
	docker build . \
		--build-arg http_proxy=$(HTTP_PROXY) \
		--build-arg https_proxy=$(HTTPS_PROXY) \
		--build-arg no_proxy=$(NO_PROXY) \
		-t edgexfoundry/device-camera:$(GIT_SHA) \
		-t edgexfoundry/device-camera:$(VERSION)-dev

test:
	go mod tidy
	go test -coverprofile=coverage.out ./...
	go vet ./...
	./bin/test-attribution.sh

check-lint:
	which golint || (go get -u golang.org/x/lint/golint)

lint: check-lint
	golint ./...

coveragehtml:
	go tool cover -html=coverage.out -o coverage.html

format:
	gofmt -l .
	[ "`gofmt -l .`" = "" ]

update:
	$(GO) mod download

clean:
	rm -f $(MICROSERVICES)
