const express = require('express');

const app = express();
app.use(express.json());

// Application metadata
const APP_INFO = {
  name: 'DevOps Batch 14 Demo App',
  assignment: 'Server Monitoring, Logging & CI Pipeline',
  version: '1.0.0',
  author: 'H. M. Masum Billah'
};

// Root endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Welcome to DevOps Batch 14 CI Pipeline & Monitoring Demonstration',
    timestamp: new Date().toISOString(),
    data: APP_INFO
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  const memoryUsage = process.memoryUsage();
  res.status(200).json({
    status: 'healthy',
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
    memory: {
      rss: `${Math.round(memoryUsage.rss / 1024 / 1024)} MB`,
      heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)} MB`,
      heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)} MB`
    }
  });
});

// System info endpoint
app.get('/api/info', (req, res) => {
  res.status(200).json({
    status: 'success',
    system: {
      nodeVersion: process.version,
      platform: process.platform,
      arch: process.arch
    },
    app: APP_INFO
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    status: 'error',
    message: `Route ${req.originalUrl} not found`
  });
});

module.exports = app;
