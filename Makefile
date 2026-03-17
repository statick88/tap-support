# =============================================================================
# TikTok Tap Support - Makefile
# Built by Statick | https://statick.dev
# =============================================================================

.PHONY: help build test lint clean install run build-docker run-docker stop-docker
.PHONY: fmt vet staticcheck security-check unit-tests coverage benchmark
.PHONY: docs proto generate run-auto run-stress docs-open

# Configuration
BINARY_NAME=tap-support
BINARY_DIR=bin
BUILD_DIR=.
VERSION=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS=-ldflags "-s -w -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME}"

# Colors
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[0;33m
BLUE=\033[0;34m
NC=\033[0m # No Color

# Default target
help:
	@echo ""
	@echo "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
	@echo "${BLUE}  TikTok Tap Support - Makefile${NC}"
	@echo "${BLUE}  Built by Statick | https://statick.dev${NC}"
	@echo "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
	@echo ""
	@echo "${GREEN}Usage:${NC}"
	@echo "  make build          Build the application"
	@echo "  make test           Run all tests"
	@echo "  make lint           Run linters (fmt, vet, staticcheck)"
	@echo "  make clean          Clean build artifacts"
	@echo "  make install        Install dependencies"
	@echo "  make run            Run the application"
	@echo "  make run-auto       Run with auto-tapping"
	@echo "  make run-stress     Run stress test"
	@echo "  make coverage       Run tests with coverage"
	@echo "  make benchmark      Run benchmarks"
	@echo "  make docker-build   Build Docker image"
	@echo "  make docker-run     Run Docker container"
	@echo ""
	@echo "${YELLOW}Development:${NC}"
	@echo "  make fmt            Format code"
	@echo "  make vet            Run go vet"
	@echo "  make staticcheck    Run staticcheck"
	@echo "  make security       Run security checks"
	@echo ""

# =============================================================================
# Build Targets
# =============================================================================

build: clean
	@echo ""
	@echo "${BLUE}[BUILD]${NC} Building ${BINARY_NAME}..."
	@mkdir -p ${BINARY_DIR}
	go build ${LDFLAGS} -o ${BINARY_DIR}/${BINARY_NAME} ./cmd/tap-support
	@echo "${GREEN}[OK]${NC} Built: ${BINARY_DIR}/${BINARY_NAME}"
	@echo ""

build-all: clean
	@echo "${BLUE}[BUILD]${NC} Building all platforms..."
	@mkdir -p ${BINARY_DIR}
	GOOS=darwin GOARCH=amd64 go build ${LDFLAGS} -o ${BINARY_DIR}/${BINARY_NAME}-darwin-amd64 ./cmd/tap-support
	GOOS=darwin GOARCH=arm64 go build ${LDFLAGS} -o ${BINARY_DIR}/${BINARY_NAME}-darwin-arm64 ./cmd/tap-support
	GOOS=linux GOARCH=amd64 go build ${LDFLAGS} -o ${BINARY_DIR}/${BINARY_NAME}-linux-amd64 ./cmd/tap-support
	@echo "${GREEN}[OK]${NC} Built all platforms in ${BINARY_DIR}/"

clean:
	@echo "${YELLOW}[CLEAN]${NC} Cleaning build artifacts..."
	rm -rf ${BINARY_DIR}
	rm -f ${BINARY_NAME}
	go clean -cache
	@echo "${GREEN}[OK]${NC} Clean complete"

# =============================================================================
# Test Targets
# =============================================================================

test: unit-tests
	@echo ""

unit-tests:
	@echo "${BLUE}[TEST]${NC} Running unit tests..."
	go test -v -race -coverprofile=coverage.out ./...
	@echo "${GREEN}[OK]${NC} Tests passed"

coverage:
	@echo "${BLUE}[COVERAGE]${NC} Running tests with coverage..."
	go test -coverprofile=coverage.out -covermode=atomic ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "${GREEN}[OK]${NC} Coverage report: coverage.html"

benchmark:
	@echo "${BLUE}[BENCHMARK]${NC} Running benchmarks..."
	go test -bench=. -benchmem ./...

# =============================================================================
# Lint Targets
# =============================================================================

lint: fmt vet staticcheck security-check
	@echo "${GREEN}[OK]${NC} All linters passed"

fmt:
	@echo "${BLUE}[FMT]${NC} Formatting code..."
	go fmt ./...
	go fmt ./...

vet:
	@echo "${BLUE}[VET]${NC} Running go vet..."
	go vet ./...

staticcheck:
	@echo "${BLUE}[STATIC]${NC} Running staticcheck..."
	@command -v staticcheck >/dev/null 2>&1 || go install honnef.co/go/tools/cmd/staticcheck@latest
	staticcheck ./...

security-check:
	@echo "${BLUE}[SECURITY]${NC} Running security checks..."
	@command -v gosec >/dev/null 2>&1 || go install github.com/securego/gosec/cmd/gosec@latest
	gosec -exclude=G104 ./...

# =============================================================================
# Run Targets
# =============================================================================

run: build
	@echo "${BLUE}[RUN]${NC} Starting ${BINARY_NAME}..."
	@./${BINARY_DIR}/${BINARY_NAME}

run-auto: build
	@echo "${BLUE}[RUN]${NC} Starting ${BINARY_NAME} with auto-tap..."
	TIKTOK_AUTO_TAP=true ./${BINARY_DIR}/${BINARY_NAME}

run-stress:
	@echo "${BLUE}[STRESS]${NC} Running stress test..."
	@chmod +x run_stress_test.sh
	@./run_stress_test.sh

# =============================================================================
# Docker Targets
# =============================================================================

docker-build:
	@echo "${BLUE}[DOCKER]${NC} Building Docker image..."
	docker build -t statick/tap-support:latest .
	docker build -t statick/tap-support:${VERSION} .

docker-run:
	@echo "${BLUE}[DOCKER]${NC} Running Docker container..."
	docker run -it --rm -e TIKTOK_USERNAME=yourusername statick/tap-support:latest

docker-build-multi:
	@echo "${BLUE}[DOCKER]${NC} Building multi-platform image..."
	docker buildx build --platform linux/amd64,linux/arm64 -t statick/tap-support:latest .

# =============================================================================
# Install Targets
# =============================================================================

install: build
	@echo "${BLUE}[INSTALL]${NC} Installing ${BINARY_NAME} to /usr/local/bin..."
	@if [ "$(shell id -u)" = "0" ]; then \
		cp ${BINARY_DIR}/${BINARY_NAME} /usr/local/bin/; \
	else \
		sudo cp ${BINARY_DIR}/${BINARY_NAME} /usr/local/bin/; \
	fi
	@echo "${GREEN}[OK]${NC} Installed to /usr/local/bin/${BINARY_NAME}"

deps:
	@echo "${BLUE}[DEPS]${NC} Updating dependencies..."
	go mod download
	go mod tidy

deps-update:
	@echo "${BLUE}[DEPS]${NC} Updating all dependencies..."
	go get -u ./...
	go mod tidy

# =============================================================================
# Documentation Targets
# =============================================================================

docs:
	@echo "${BLUE}[DOCS]${NC} Building documentation..."
	@mkdir -p docs
	@echo "# API Documentation" > docs/api.md
	go doc ./... >> docs/api.md

docs-serve:
	@echo "${BLUE}[DOCS]${NC} Starting documentation server..."
	command -v godoc >/dev/null 2>&1 || go install golang.org/x/tools/cmd/godoc@latest
	godoc -http=:6060

# =============================================================================
# Release Targets
# =============================================================================

release: test lint
	@echo "${BLUE}[RELEASE]${NC} Creating release..."
	@git tag -a v${VERSION} -m "Release ${VERSION}"
	@git push origin v${VERSION}
	@echo "${GREEN}[OK]${NC} Release ${VERSION} created"

# =============================================================================
# Development Targets
# =============================================================================

dev: build
	@echo "${BLUE}[DEV]${NC} Starting development mode..."
	@go run ./cmd/tap-support

watch:
	@echo "${BLUE}[WATCH]${NC} Watching for changes..."
	@command -v air >/dev/null 2>&1 || go install github.com/cosmtrek/air@latest
	air

tidy:
	@echo "${BLUE}[TIDY]${NC} Tidying up..."
	go mod tidy

# =============================================================================
# Info Targets
# =============================================================================

info:
	@echo ""
	@echo "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
	@echo "  ${BINARY_NAME} Information"
	@echo "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
	@echo "  Version:      ${VERSION}"
	@echo "  Build Time:   ${BUILD_TIME}"
	@echo "  Go Version:   $(shell go version)"
	@echo "  Architecture: $(shell go env GOARCH)"
	@echo "  OS:           $(shell go env GOOS)"
	@echo "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
	@echo ""

version:
	@echo "${BINARY_NAME} ${VERSION}"