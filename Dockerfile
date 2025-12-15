# syntax=docker/dockerfile:1
FROM golang:1.21-alpine AS webhook-builder

WORKDIR /build

RUN apk add --no-cache git && \
    git clone --depth 1 https://github.com/adnanh/webhook.git . && \
    go build -ldflags="-s -w" -o webhook && \
    apk del git

FROM python:3.11-alpine

# Metadata
LABEL org.opencontainers.image.title="Gazelle Origin Webhook" \
      org.opencontainers.image.description="Webhook server for gazelle-origin to generate origin.yaml files" \
      org.opencontainers.image.url="https://github.com/jee-r/gazelle-origin-webhook" \
      org.opencontainers.image.source="https://github.com/jee-r/gazelle-origin-webhook" \
      org.opencontainers.image.licenses="MIT"

# Install runtime dependencies and gazelle-origin in one layer
RUN apk add --no-cache ca-certificates bash git && \
    git clone --depth 1 https://github.com/spinfast319/gazelle-origin.git /tmp/gazelle && \
    pip install --no-cache-dir -e /tmp/gazelle && \
    rm -rf /tmp/gazelle/.git && \
    apk del git && \
    rm -rf /var/cache/apk/* /root/.cache

# Copy webhook binary
COPY --from=webhook-builder /build/webhook /usr/local/bin/webhook

# Copy hooks configuration
COPY hooks.json /hooks/hooks.json

# Create data directory and set as working directory
RUN mkdir -p /data
WORKDIR /data

# Default environment variables
ENV WEBHOOK_SECRET=changeme

EXPOSE 9000

CMD ["webhook", "-hooks", "/hooks/hooks.json", "-template", "-verbose"]
