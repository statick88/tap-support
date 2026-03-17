# =============================================================================
# TikTok Tap Support - Dockerfile
# Built by Statick | https://statick.dev
# =============================================================================

# Build Stage
FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make

# Set working directory
WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build arguments
ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev
ARG BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build the application
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags "-s -w -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME}" \
    -o tap-support ./cmd/tap-support

# Production Stage
FROM alpine:3.19

# Install runtime dependencies (no shell, no extra packages for security)
RUN apk add --no-cache --purge ca-certificates tzdata \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D appuser

# Set working directory
WORKDIR /home/appuser

# Copy binary from builder
COPY --from=builder /build/tap-support .

# Create data directory
RUN mkdir -p /home/appuser/data && \
    chown -R appuser:appgroup /home/appuser

# Set environment variables
ENV TIKTOK_STORAGE_PATH=/home/appuser/data
ENV TERM=xterm-256color

# Switch to non-root user
USER appuser

# Expose port (if needed for future HTTP server)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD exit 0

# Entry point
ENTRYPOINT ["./tap-support"]

# Default arguments
CMD ["--help"]