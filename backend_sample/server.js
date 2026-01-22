const express = require('express');
const cors = require('cors');
const fs = require('fs');
const csv = require('csv-parser');
const crypto = require('crypto');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Store users in memory
let users = [];

// Load users from CSV file
function loadUsers() {
  return new Promise((resolve, reject) => {
    const usersData = [];
    const csvPath = path.join(__dirname, 'users.csv');
    
    fs.createReadStream(csvPath)
      .pipe(csv())
      .on('data', (row) => {
        usersData.push({
          username: row.username,
          password: row.password
        });
      })
      .on('end', () => {
        users = usersData;
        console.log(`Loaded ${users.length} users from CSV`);
        resolve();
      })
      .on('error', (error) => {
        console.error('Error reading CSV file:', error);
        reject(error);
      });
  });
}

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

// Authentication endpoint
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  
  console.log('Login attempt:', username);
  
  if (!username || !password) {
    return res.status(400).json({
      success: false,
      message: 'Username and password are required'
    });
  }
  
  // Check credentials
  const user = users.find(u => u.username === username && u.password === password);
  
  if (user) {
    res.json({
      success: true,
      message: 'Login successful',
      username: user.username
    });
  } else {
    res.status(401).json({
      success: false,
      message: 'Invalid username or password'
    });
  }
});

// Hash generation endpoint
app.post('/api/hash', (req, res) => {
  const { message } = req.body;
  
  console.log('Hash request for message:', message);
  
  if (!message) {
    return res.status(400).json({
      success: false,
      message: 'Message is required'
    });
  }
  
  // Calculate SHA-256 hash
  const hash = crypto.createHash('sha256').update(message).digest('hex');
  
  res.json({
    success: true,
    message: 'Hash generated successfully',
    originalMessage: message,
    hash: hash,
    algorithm: 'SHA-256',
    timestamp: new Date().toISOString()
  });
});

// Calculation endpoint
app.post('/api/calculate', (req, res) => {
  const { firstNumber, operator, secondNumber } = req.body;
  
  console.log('Calculation request:', firstNumber, operator, secondNumber);
  
  if (firstNumber === undefined || !operator || secondNumber === undefined) {
    return res.status(400).json({
      success: false,
      message: 'First number, operator, and second number are required'
    });
  }
  
  const num1 = parseFloat(firstNumber);
  const num2 = parseFloat(secondNumber);
  
  if (isNaN(num1) || isNaN(num2)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid numbers provided'
    });
  }
  
  let result;
  
  switch (operator) {
    case '+':
      result = num1 + num2;
      break;
    case '-':
      result = num1 - num2;
      break;
    case '*':
      result = num1 * num2;
      break;
    case '/':
      if (num2 === 0) {
        return res.status(400).json({
          success: false,
          message: 'Cannot divide by zero'
        });
      }
      result = num1 / num2;
      break;
    default:
      return res.status(400).json({
        success: false,
        message: 'Invalid operator. Use +, -, *, or /'
      });
  }
  
  res.json({
    success: true,
    message: 'Calculation completed',
    firstNumber: num1,
    operator: operator,
    secondNumber: num2,
    result: result,
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    usersLoaded: users.length,
    timestamp: new Date().toISOString() 
  });
});

// Start server after loading users
loadUsers()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server is running on http://localhost:${PORT}`);
      console.log(`Endpoints available:`);
      console.log(`  POST /api/login - Authentication`);
      console.log(`  POST /api/hash - Generate hash`);
      console.log(`  POST /api/calculate - Perform calculation`);
      console.log(`  GET /health - Health check`);
    });
  })
  .catch((error) => {
    console.error('Failed to start server:', error);
    process.exit(1);
  });
