# LOCALSTACK CHANGES 2022-03-10: remove linker flags and add gc flags for delve debugger
# LOCALSTACK CHANGES 2022-03-28: change compile src folder
# LOCALSTACK CHANGES 2022-11-14: add --rm flag to compile-with-docker

# RELEASE_BUILD_LINKER_FLAGS disables DWARF and symbol table generation to reduce binary size
#RELEASE_BUILD_LINKER_FLAGS=-s -w

BINARY_NAME=aws-lambda-rie
ARCH=x86_64
GO_ARCH_x86_64 := amd64
GO_ARCH_arm64 := arm64
DESTINATION_x86_64 := bin/${BINARY_NAME}-x86_64
DESTINATION_arm64 := bin/${BINARY_NAME}-arm64

compile-with-docker-all:
	make ARCH=x86_64 compile-with-docker
	make ARCH=arm64 compile-with-docker

compile-lambda-linux-all:
	make ARCH=x86_64 compile-lambda-linux
	make ARCH=arm64 compile-lambda-linux

compile-with-docker:
	docker run --rm --env GOPROXY=direct -v $(shell pwd):/LambdaRuntimeLocal -w /LambdaRuntimeLocal golang:1.19 make ARCH=${ARCH} compile-lambda-linux

compile-lambda-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=${GO_ARCH_${ARCH}} go build -ldflags "${RELEASE_BUILD_LINKER_FLAGS}" -gcflags="${GC_FLAGS}" -o ${DESTINATION_${ARCH}} ./cmd/localstack

tests:
	go test ./...

integ-tests-and-compile: tests 
	make compile-lambda-linux-all
	make integ-tests

integ-tests-with-docker: tests 
	make compile-with-docker-all
	make integ-tests
	
integ-tests:
	python3 -m venv .venv
	.venv/bin/pip install --upgrade pip
	.venv/bin/pip install requests parameterized
	.venv/bin/python3 test/integration/local_lambda/test_end_to_end.py
