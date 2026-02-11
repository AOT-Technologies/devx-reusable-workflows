# Demo Python App

Flask REST API for testing the DevX CI/CD platform.

## Features

- ✅ Python 3.11
- ✅ Flask 3.0 REST API
- ✅ Pytest unit tests with coverage
- ✅ Gunicorn production server
- ✅ Docker multi-stage build
- ✅ Health check endpoints
- ✅ DevX platform integration

## Endpoints

- `GET /` - Hello world
- `GET /health` - Health check
- `GET /api/info` - Application info

## Local Development
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest

# Run locally
python src/demo_app/app.py

# Access
curl http://localhost:5000
```

## Docker
```bash
# Build
docker build -t demo-python-app .

# Run
docker run -p 5000:5000 demo-python-app

# Test
curl http://localhost:5000/health
```

## Test Coverage
```bash
pytest --cov=src/demo_app --cov-report=html
# Open htmlcov/index.html
```
