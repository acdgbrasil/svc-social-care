# syntax=docker/dockerfile:1.7
FROM swift:6.2-jammy AS build

WORKDIR /build

LABEL org.opencontainers.image.source="https://github.com/acdgbrasil/svc-social-care"
LABEL org.opencontainers.image.description="ACDG svc-social-care service"
LABEL org.opencontainers.image.licenses="Proprietary"

COPY Package.swift Package.resolved ./
RUN swift package resolve

COPY Sources ./Sources
COPY Tests ./Tests
RUN swift build -c release --product social-care-s

FROM swift:6.2-jammy-slim

WORKDIR /app
COPY --from=build /build/.build/release/social-care-s /app/social-care-s

EXPOSE 3000
CMD ["/app/social-care-s"]
