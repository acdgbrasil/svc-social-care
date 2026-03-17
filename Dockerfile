# syntax=docker/dockerfile:1.7
FROM swift:6.2-jammy AS build

WORKDIR /build

LABEL org.opencontainers.image.source="https://github.com/acdgbrasil/svc-social-care"
LABEL org.opencontainers.image.description="ACDG svc-social-care service"
LABEL org.opencontainers.image.licenses="Proprietary"

RUN apt-get update && apt-get install -y curl build-essential autoconf automake libtool && \
    curl -sL https://github.com/jedisct1/libsodium/archive/refs/heads/stable.tar.gz | tar xz && \
    cd libsodium-stable && ./autogen.sh && ./configure && make -j$(nproc) && make install && ldconfig && \
    cd .. && rm -rf libsodium-stable && \
    apt-get purge -y build-essential autoconf automake libtool && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

COPY Package.swift Package.resolved ./
RUN swift package resolve

COPY Sources ./Sources
COPY Tests ./Tests
RUN swift build -c release --product social-care-s

FROM swift:6.2-jammy-slim

COPY --from=build /usr/local/lib/libsodium.so* /usr/local/lib/
RUN ldconfig

WORKDIR /app
COPY --from=build /build/.build/release/social-care-s /app/social-care-s

EXPOSE 3000
CMD ["/app/social-care-s"]
