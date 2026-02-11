"""
Demo Python Flask Application
Simple REST API for testing DevX CI/CD platform
"""
from flask import Flask, jsonify
import os
import sys

app = Flask(__name__)


@app.route("/")
def hello():
    """Hello world endpoint"""
    return jsonify({
        "message": "Hello from Demo Python App!",
        "status": "running",
        "language": "Python",
        "framework": "Flask",
        "version": "1.0.0"
    })


@app.route("/health")
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "python_version": sys.version,
        "flask_version": "3.0.0"
    }), 200


@app.route("/api/info")
def info():
    """Application information endpoint"""
    return jsonify({
        "application": "demo-python-app",
        "version": "1.0.0",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "python_version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    })


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        "error": "Not Found",
        "message": "The requested resource was not found"
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        "error": "Internal Server Error",
        "message": "An unexpected error occurred"
    }), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug = os.getenv("DEBUG", "False").lower() == "true"
    app.run(host="0.0.0.0", port=port, debug=debug)
