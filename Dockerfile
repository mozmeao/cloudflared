FROM golang:1.12-alpine as builder

ARG REPO_URL="https://github.com/cloudflare/cloudflared.git"
ARG REFERENCE=""

WORKDIR /go/src/github.com/cloudflare/cloudflared/
RUN apk add --no-cache git gcc musl-dev upx ca-certificates
RUN [ -n "$REFERENCE" ] && REF="-b $REFERENCE" || REF=""; \
git clone --depth=1 ${REF} ${REPO_URL} .
RUN VERSION=$(git describe --tags --always --dirty="-dev") && \
DATE=$(date -u '+%Y-%m-%dT%H:%MZ') && \
go build -ldflags "-X main.Version=\"${VERSION}\" -X main.BuildTime=\"${DATE}\"" \
-installsuffix cgo -o cloudflared ./cmd/cloudflared
RUN upx --no-progress cloudflared

FROM alpine:3.9
COPY --from=builder /go/src/github.com/cloudflare/cloudflared/cloudflared /usr/local/bin/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
ENTRYPOINT ["cloudflared"]
CMD ["version"]
