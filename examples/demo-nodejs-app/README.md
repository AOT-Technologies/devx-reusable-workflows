# Demo Node.js Application

This is a demonstration project showcasing the **DevX Reusable Workflows** for CI/CD automation.

## 🚀 Features

- **Express REST API** with users and tasks endpoints
- **Unit Tests** with Jest (80%+ coverage requirement)
- **Docker Support** with multi-stage builds
- **Security Scanning** (SAST, Container scanning, SBOM)
- **Automated CI/CD** with GitHub Actions
- **Health Checks** for monitoring
- **Error Handling** middleware
- **ESLint** for code quality

## 📋 Prerequisites

- Node.js 20.x or higher
- npm 10.x or higher
- Docker (optional, for container builds)

## 🛠️ Installation
```bash
# Clone repository
git clone https://github.com/your-org/demo-nodejs-app.git
cd demo-nodejs-app

# Install dependencies
npm install
```

## 🏃 Running Locally
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start

# Run tests
npm test

# Run tests in watch mode
npm run test:watch

# Lint code
npm run lint
```

## 📡 API Endpoints

### Root
- `GET /` - API information and available endpoints

### Health
- `GET /health` - Health check endpoint

### Users
- `GET /api/users` - List all users
- `GET /api/users/:id` - Get specific user
- `POST /api/users` - Create new user

### Tasks
- `GET /api/tasks` - List all tasks (supports ?status= and ?priority= filters)
- `GET /api/tasks/:id` - Get specific task
- `POST /api/tasks` - Create new task
- `PATCH /api/tasks/:id` - Update task

### Info
- `GET /api/info` - API information

## 🧪 Testing
```bash
# Run all tests with coverage
npm test

# Watch mode for development
npm run test:watch
```

**Coverage Requirements:**
- Branches: 80%
- Functions: 80%
- Lines: 80%
- Statements: 80%

## 🐳 Docker
```bash
# Build image
docker build -t demo-nodejs-app .

# Run container
docker run -p 3000:3000 demo-nodejs-app

# Test health check
curl http://localhost:3000/health
```

## 🔧 CI/CD Pipeline

This project uses **DevX Reusable Workflows** for automated CI/CD:

### Pipeline Stages:
1. **Configuration Load** - Validates devx-ci.yaml
2. **Security Gates** (Parallel)
   - SAST scanning with Semgrep
3. **Build & Test**
   - Install dependencies (with caching)
   - Run unit tests with Jest
   - Capture coverage reports
4. **Docker Build**
   - Multi-stage Dockerfile
   - Push to container registry
5. **Security Scans**
   - Trivy container scanning
   - SBOM generation
   - SBOM vulnerability analysis

### View Results:
- **Actions Tab** - See pipeline runs
- **Security Tab** - View security findings
- **Artifacts** - Download coverage reports

## 📊 Project Structure

```bash
demo-nodejs-app/
├── src/                    # Source code
│   ├── index.js           # Main application
│   ├── routes/            # API routes
│   └── middleware/        # Express middleware
├── tests/                 # Test files
├── .github/workflows/     # CI/CD configuration
├── devx-ci.yaml          # DevX pipeline config
├── Dockerfile            # Container definition
└── package.json          # Dependencies
```
## 🔒 Security

This project includes multiple security layers:
- **SAST** - Source code analysis
- **Dependency Scanning** - Check for vulnerable packages
- **Container Scanning** - OS and package vulnerabilities
- **SBOM** - Software bill of materials for audit trail
- **Helmet.js** - Security headers
- **CORS** - Cross-origin resource sharing

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `npm test`
5. Submit a pull request

## 🆘 Troubleshooting

**Tests failing?**
```bash
npm test -- --verbose
```

**Docker build issues?**
```bash
docker build -t demo-nodejs-app . --no-cache
```

**Port already in use?**
```bash
# Change port in .env or:
PORT=3001 npm start
```

## 📞 Support

For issues or questions:
- Check the [DevX Workflows Documentation](https://github.com/AOT-Technologies/devx-reusable-workflows)
- Open an issue in this repository
- Contact DevOps team

---

**Built with ❤️ using DevX Reusable Workflows**
