# syntax=docker/dockerfile:1.7
FROM swift:6.2-jammy AS build

WORKDIR /build

LABEL org.opencontainers.image.source="https://github.com/acdgbrasil/svc-social-care"
LABEL org.opencontainers.image.description="ACDG svc-social-care service"
LABEL org.opencontainers.image.licenses="Proprietary"

RUN apt-get update && apt-get install -y libsodium-dev && rm -rf /var/lib/apt/lists/*

COPY Package.swift Package.resolved ./
RUN swift package resolve

COPY Sources ./Sources
COPY Tests ./Tests
RUN swift build -c release --product social-care-s

FROM swift:6.2-jammy-slim

RUN apt-get update && apt-get install -y libsodium23 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /build/.build/release/social-care-s /app/social-care-s

EXPOSE 3000
CMD ["/app/social-care-s"]
