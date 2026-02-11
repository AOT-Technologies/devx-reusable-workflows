# Multi-stage build for optimal image size
FROM node:20-alpine AS builder

WORKDIR /app

# The artifact is downloaded by the CI pipeline.
# ARTIFACT_NAME is passed as a build argument.
ARG ARTIFACT_NAME

COPY ${ARTIFACT_NAME} ./

RUN echo "📦 Extracting artifact: ${ARTIFACT_NAME}..." && \
    # npm pack/publish creates a .tgz with a 'package/' prefix.
    # We use --strip-components=1 to remove it if it exists, 
    # or handle it gracefully if it doesn't.
    if tar -tf ${ARTIFACT_NAME} | grep -q "^package/"; then \
      tar -xzf ${ARTIFACT_NAME} --strip-components=1; \
    else \
      tar -xzf ${ARTIFACT_NAME}; \
    fi && \
    rm ${ARTIFACT_NAME}

# ============================================
# Production Stage
# ============================================
FROM node:20-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init curl

# Create non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001 -G nodejs

WORKDIR /app

# Copy bundled application from builder
# We expect 'dist' and 'package.json' to be present after extraction
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Install production dependencies
# We use 'npm install' because 'package-lock.json' is excluded from published packages
RUN npm install --omit=dev --no-audit

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application using the bundled file
CMD ["node", "dist/index.js"]