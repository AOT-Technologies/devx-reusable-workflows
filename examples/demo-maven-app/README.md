# Demo Maven App

Spring Boot application for testing the DevX CI/CD platform.

## Features

- ✅ Spring Boot 3.2.1
- ✅ Java 17
- ✅ REST API endpoints
- ✅ Health checks (Spring Actuator)
- ✅ Unit tests (JUnit 5)
- ✅ Docker multi-stage build
- ✅ DevX platform integration

## Endpoints

- `GET /` - Hello world
- `GET /api/status` - Application status
- `GET /actuator/health` - Health check

## Local Development
```bash
# Run tests
mvn test

# Build
mvn clean package

# Run locally
java -jar target/demo-maven-app.jar

# Access
curl http://localhost:8080
```

## Docker
```bash
# Build
docker build -t demo-maven-app .

# Run
docker run -p 8080:8080 demo-maven-app
```
