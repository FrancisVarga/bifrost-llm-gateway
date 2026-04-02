# syntax=docker/dockerfile:1
# Root Dockerfile for Temps deployment — uses local Go workspace
# Based on transports/Dockerfile.local for pre-release builds where
# module versions in transports/ depend on unpublished local changes

# --- UI Build Stage: Build the Next.js frontend ---
FROM node:25-alpine3.23 AS ui-builder
WORKDIR /app

# Copy dependency manifests first (changes less often → cached layer)
COPY ui/package.json ui/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
  npm ci

# Copy UI source code (changes more often → separate layer)
COPY ui/ ./

# Build UI
RUN npx next build
RUN node scripts/fix-paths.js

# --- Go Dependency Stage: Download modules separately for caching ---
FROM golang:1.26.1-alpine3.23 AS deps
WORKDIR /build

# Install build toolchain (cached unless base image changes)
RUN apk add --no-cache gcc musl-dev sqlite-dev binutils binutils-gold

ENV CGO_ENABLED=1 GOOS=linux

# Copy ONLY go.mod/go.sum files from all modules (changes less often)
COPY core/go.mod core/go.sum ./core/
COPY framework/go.mod framework/go.sum ./framework/
COPY plugins/governance/go.mod plugins/governance/go.sum ./plugins/governance/
COPY plugins/jsonparser/go.mod plugins/jsonparser/go.sum ./plugins/jsonparser/
COPY plugins/litellmcompat/go.mod plugins/litellmcompat/go.sum ./plugins/litellmcompat/
COPY plugins/logging/go.mod plugins/logging/go.sum ./plugins/logging/
COPY plugins/maxim/go.mod plugins/maxim/go.sum ./plugins/maxim/
COPY plugins/mocker/go.mod plugins/mocker/go.sum ./plugins/mocker/
COPY plugins/otel/go.mod plugins/otel/go.sum ./plugins/otel/
COPY plugins/semanticcache/go.mod plugins/semanticcache/go.sum ./plugins/semanticcache/
COPY plugins/telemetry/go.mod plugins/telemetry/go.sum ./plugins/telemetry/
COPY transports/go.mod transports/go.sum ./transports/

# Set up Go workspace
RUN go work init && \
  go work use ./core && \
  go work use ./framework && \
  go work use ./plugins/governance && \
  go work use ./plugins/jsonparser && \
  go work use ./plugins/litellmcompat && \
  go work use ./plugins/logging && \
  go work use ./plugins/maxim && \
  go work use ./plugins/mocker && \
  go work use ./plugins/otel && \
  go work use ./plugins/semanticcache && \
  go work use ./plugins/telemetry && \
  go work use ./transports

# Download all external dependencies (cached until go.mod/go.sum change)
RUN --mount=type=cache,target=/go/pkg/mod \
  cd /build/transports && go mod download

# --- Go Build Stage: Compile the binary ---
FROM deps AS builder

# Now copy all source code (this layer busts only on source changes,
# not on dependency changes — deps are already cached above)
COPY core/ ./core/
COPY framework/ ./framework/
COPY plugins/ ./plugins/
COPY transports/ ./transports/

# Copy UI build output
COPY --from=ui-builder /app/out ./transports/bifrost-http/ui

# Build the binary with cached module and build caches
ARG VERSION=unknown
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
  cd /build/transports && \
  go build \
    -ldflags="-w -s -X main.Version=v${VERSION} -extldflags '-static'" \
    -a -trimpath \
    -tags "sqlite_static" \
    -o /app/main \
    ./bifrost-http

# Verify build succeeded
RUN test -f /app/main || (echo "Build failed" && exit 1)

# --- Runtime Stage: Minimal runtime image ---
FROM alpine:3.23.3
WORKDIR /app

# Install runtime dependencies for CGO-enabled binary
RUN apk add --no-cache musl libgcc ca-certificates wget

# Create data directory and set up user
COPY --from=builder /app/main .
COPY --from=builder /build/transports/docker-entrypoint.sh .

# Getting arguments
ARG ARG_APP_PORT=8080
ARG ARG_APP_HOST=0.0.0.0
ARG ARG_LOG_LEVEL=info
ARG ARG_LOG_STYLE=json
ARG ARG_APP_DIR=/app/data

# Environment variables with defaults (can be overridden at runtime)
ENV APP_PORT=$ARG_APP_PORT \
  APP_HOST=$ARG_APP_HOST \
  LOG_LEVEL=$ARG_LOG_LEVEL \
  LOG_STYLE=$ARG_LOG_STYLE \
  APP_DIR=$ARG_APP_DIR

# Go runtime performance tuning
ENV GOGC="" \
  GOMEMLIMIT=""

RUN mkdir -p $APP_DIR/logs && \
  adduser -D -s /bin/sh appuser && \
  chown -R appuser:appuser /app && \
  chmod +x /app/docker-entrypoint.sh
USER appuser

# Declare volume for data persistence
VOLUME ["/app/data"]
EXPOSE $APP_PORT

# Health check for container status monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 -O /dev/null http://127.0.0.1:${APP_PORT}/health || exit 1

# Use entrypoint script that handles volume permissions and argument processing
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["/app/main"]
