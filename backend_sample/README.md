# Backend Sample - Node.js API

Simple Node.js/Express backend to handle greeting requests from the Flutter web app.

## Setup

1. Install dependencies:
```bash
npm install
```

## Run

Start the server:
```bash
npm start
```

Or use nodemon for auto-reload during development:
```bash
npm run dev
```

The server will run on `http://localhost:3000`

## API Endpoints

### POST /api/greeting
Accepts a greeting message from the Flutter app.

**Request:**
```json
{
  "greeting": "Hello, World!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Greeting received successfully",
  "receivedGreeting": "Hello, World!",
  "timestamp": "2026-01-20T12:00:00.000Z"
}
```

**Response (400):**
```json
{
  "success": false,
  "message": "Greeting is required"
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-01-20T12:00:00.000Z"
}
```

## CORS

CORS is enabled to allow requests from the Flutter web app running on a different origin.
