"""
Unit tests for Flask application
"""
import pytest
import json
from src.demo_app.app import app


@pytest.fixture
def client():
    """Create test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_hello_endpoint(client):
    """Test the hello endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['message'] == "Hello from Demo Python App!"
    assert data['language'] == "Python"
    assert data['framework'] == "Flask"


def test_health_endpoint(client):
    """Test the health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['status'] == "healthy"
    assert 'python_version' in data


def test_info_endpoint(client):
    """Test the info endpoint"""
    response = client.get('/api/info')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['application'] == "demo-python-app"
    assert data['version'] == "1.0.0"
    assert 'python_version' in data


def test_404_handler(client):
    """Test 404 error handler"""
    response = client.get('/nonexistent')
    assert response.status_code == 404
    
    data = json.loads(response.data)
    assert data['error'] == "Not Found"


def test_response_content_type(client):
    """Test that responses are JSON"""
    response = client.get('/')
    assert response.content_type == 'application/json'
