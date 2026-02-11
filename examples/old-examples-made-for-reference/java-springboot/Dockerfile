# Optimized Java Dockerfile for DevX Pipeline
FROM eclipse-temurin:17-jre-alpine

# Security: Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# The artifact is downloaded by the CI pipeline.
ARG ARTIFACT_NAME
COPY ${ARTIFACT_NAME} app.jar

# Set ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

EXPOSE 8080
HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# JVM optimizations for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]