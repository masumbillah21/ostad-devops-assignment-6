const request = require('supertest');
const app = require('../src/app');

describe('DevOps Batch 14 Demo App API Tests', () => {
  describe('GET /', () => {
    it('should return 200 status with welcome message and app details', async () => {
      const res = await request(app).get('/');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('status', 'success');
      expect(res.body).toHaveProperty('message');
      expect(res.body.data).toHaveProperty('name', 'DevOps Batch 14 Demo App');
      expect(res.body.data).toHaveProperty('assignment', 'Server Monitoring, Logging & CI Pipeline');
    });
  });

  describe('GET /health', () => {
    it('should return 200 and healthy status with memory metrics', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('status', 'healthy');
      expect(res.body).toHaveProperty('uptimeSeconds');
      expect(res.body).toHaveProperty('memory');
      expect(res.body.memory).toHaveProperty('rss');
      expect(res.body.memory).toHaveProperty('heapTotal');
      expect(res.body.memory).toHaveProperty('heapUsed');
    });
  });

  describe('GET /api/info', () => {
    it('should return runtime environment and system details', async () => {
      const res = await request(app).get('/api/info');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('status', 'success');
      expect(res.body).toHaveProperty('system');
      expect(res.body.system).toHaveProperty('nodeVersion');
    });
  });

  describe('404 Handling', () => {
    it('should return 404 for unmapped endpoints', async () => {
      const res = await request(app).get('/invalid-endpoint-xyz');
      expect(res.statusCode).toEqual(404);
      expect(res.body).toHaveProperty('status', 'error');
      expect(res.body.message).toContain('not found');
    });
  });
});
