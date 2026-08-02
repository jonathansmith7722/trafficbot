# Stage 1: Build
FROM node:18-slim AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Skip postinstall and puppeteer download during npm install
RUN npm install --ignore-scripts

# Copy source code and build
COPY . .
RUN npm run build

# Stage 2: Runtime
FROM ghcr.io/puppeteer/puppeteer:latest AS runtime

WORKDIR /app

# Copy built application and dependencies from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/useragent ./useragent

# Environment setup
ENV NODE_ENV=production
ENV LOG_LEVEL=info

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('fs').existsSync('./dist/main.js') || process.exit(1)"

# Entrypoint
ENTRYPOINT ["node", "dist/main.js"]
