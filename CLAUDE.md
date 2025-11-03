# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a demonstration Go API project that serves as a practical example for the branching model workflow proposal. It's a minimal HTTP API with health checks and item management endpoints, designed to showcase the Git workflow described in the parent proposal documentation.

## Project Structure

```
.
├── main.go              # HTTP server setup, middleware, main entry point
├── handlers/            # HTTP request handlers
│   └── handlers.go      # Item CRUD handlers and health check
├── .github/workflows/   # GitHub Actions for branch management
│   └── sync-develop.yml # Auto-sync develop branch from master
└── docs/                # Documentation (copy of branching model proposal)
```

## Architecture

**Simple HTTP API with standard library only:**
- No external dependencies (uses only Go standard library)
- In-memory data storage (demo purposes)
- RESTful JSON API endpoints
- Request logging middleware

**Key components:**
- `main.go:main()` - Server initialization and routing
- `handlers.Item` - Core data model
- `handlers.Response` - Standard JSON response format
- `loggingMiddleware()` - Request logging

## Commands

### Building and Running

```bash
# Build the binary
go build -o api .

# Run the server (default port 8080)
./api

# Run with custom port
PORT=3000 ./api

# Run directly without building
go run main.go
```

### Testing the API

```bash
# Health check
curl http://localhost:8080/health

# Get all items
curl http://localhost:8080/api/v1/items

# Get specific item by ID
curl http://localhost:8080/api/v1/items/1
```

### Development

```bash
# Format code
go fmt ./...

# Build for current platform
go build -o api .

# Clean build artifacts
rm -f api
```

## API Endpoints

- `GET /health` - Health check endpoint returning status and timestamp
- `GET /api/v1/items` - List all items
- `GET /api/v1/items/{id}` - Get single item by ID

All responses follow the `Response` struct format:
```json
{
  "success": true,
  "data": {...},
  "error": ""
}
```

## Branching Workflow

This repository demonstrates the branching model proposal. See `docs/branching-model.md` for the complete workflow documentation.

**Key workflow elements:**

1. **Master branch**: Production-ready code, requires PR reviews
2. **Develop branch**: Integration/staging environment, auto-syncs from master
3. **Feature branches**: Created from master, merged to develop for testing, then PR to master

**GitHub Action behavior:**
- Automatically merges master → develop after every PR merge
- Creates issues on merge conflicts with resolution instructions
- Uses `[skip ci]` to prevent infinite loops

## Project Purpose

This is a demo application to test and validate the branching model workflow. It provides:
- A working codebase for practicing the Git workflow
- Simple endpoints to test deployments
- GitHub Action configuration to automate develop branch syncing
- Minimal complexity to focus on workflow rather than implementation details