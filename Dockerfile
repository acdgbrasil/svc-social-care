# syntax=docker/dockerfile:1.7
FROM oven/bun:1.1-alpine

WORKDIR /app

LABEL org.opencontainers.image.source="https://github.com/acdgbrasil/svc-social-care"
LABEL org.opencontainers.image.description="ACDG svc-social-care service"
LABEL org.opencontainers.image.licenses="Proprietary"

COPY package.json .
RUN bun install

COPY . .

EXPOSE 3000
CMD ["bun", "src/index.ts"]
