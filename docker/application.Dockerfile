# syntax=docker/dockerfile:1
FROM node:18-bookworm-slim AS builder
WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM node:18-bookworm-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=9000
ENV UPLOAD_PATH=/app/upload

COPY --from=builder /app/node_modules ./node_modules
COPY . .

RUN mkdir -p /app/upload

EXPOSE 9000
CMD ["node", "server.js"]
