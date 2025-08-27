const express = require('express');
const WebSocket = require('ws');
const http = require('http');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Middleware
app.use(express.json());

// Health endpoint that returns JSON
app.get('/health', (req, res) => {
  const response = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'ws-server'
  };
  res.json(response);
});

// Root endpoint that returns JSON
app.get('/', (req, res) => {
  const response = {
    status: 'running',
    timestamp: new Date().toISOString(),
    service: 'ws-server'
  };
  res.json(response);
});

// WebSocket connection handling
wss.on('connection', (ws, req) => {
  console.log(`WebSocket connection established from ${req.socket.remoteAddress}`);

  // Send welcome message
  const welcomeMsg = {
    type: 'welcome',
    message: 'WebSocket connection established',
    time: new Date().toISOString()
  };
  ws.send(JSON.stringify(welcomeMsg));

  // Handle incoming messages
  ws.on('message', (message) => {
    try {
      const data = message.toString();
      console.log(`Received message: ${data}`);

      // Echo the message back
      const response = {
        type: 'echo',
        message: data,
        time: new Date().toISOString()
      };

      ws.send(JSON.stringify(response));
      
      // Also send as text echo
      ws.send(data);
    } catch (error) {
      console.error('Error processing message:', error);
    }
  });

  // Handle connection close
  ws.on('close', () => {
    console.log('WebSocket connection closed');
  });

  // Handle errors
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
});

// Start server
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health endpoint: http://localhost:${PORT}/health`);
  console.log(`WebSocket endpoint: ws://localhost:${PORT}/ws`);
}); 