# Optimized Node.js Dockerfile for DevX Pipeline
FROM node:20-alpine AS builder

WORKDIR /app

# The artifact is downloaded by the CI pipeline.
ARG ARTIFACT_NAME
COPY ${ARTIFACT_NAME} ./

# Extract and prepare
RUN tar -xzf ${ARTIFACT_NAME} --strip-components=1 && rm ${ARTIFACT_NAME}

# Production stage
FROM node:20-alpine
RUN apk add --no-cache dumb-init curl
WORKDIR /app

# Copy from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# Install production dependencies
RUN npm install --omit=dev

EXPOSE 3000
HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/index.js"]