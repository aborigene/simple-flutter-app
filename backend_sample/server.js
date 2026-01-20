const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// CORS configuration - Allow all origins
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: false
};

// Middleware
app.use(cors(corsOptions));
app.use(express.json());

// POST endpoint to receive greeting
app.post('/api/greeting', (req, res) => {
  const { greeting } = req.body;
  
  console.log('Received greeting:', greeting);
  
  if (!greeting) {
    return res.status(400).json({
      success: false,
      message: 'Greeting is required'
    });
  }
  
  // Send success response
  res.status(200).json({
    success: true,
    message: 'Greeting received successfully',
    receivedGreeting: greeting,
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
  console.log(`Greeting endpoint: http://localhost:${PORT}/api/greeting`);
});
