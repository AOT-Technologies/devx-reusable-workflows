# =============================================================================
# Dockerfile for Maven Application (Runtime Only)
# =============================================================================
# This Dockerfile expects the artifact to be present in the build context.
# ARTIFACT_NAME is passed as a build argument (defaults to app.jar).
# =============================================================================

FROM eclipse-temurin:17-jre-alpine

# Security: Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# The artifact name is dynamic
ARG ARTIFACT_NAME=app.jar

# Copy the artifact from the build context
COPY ${ARTIFACT_NAME} app.jar

# Set ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Expose port
EXPOSE 8080

# JVM optimizations for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]