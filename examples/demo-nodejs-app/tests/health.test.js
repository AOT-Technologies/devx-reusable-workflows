const request = require('supertest');
const app = require('../src/index');

describe('Health Check Endpoint', () => {
  test('GET /health returns 200', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
  });

  test('GET /health returns correct structure', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toHaveProperty('status');
    expect(response.body).toHaveProperty('service');
    expect(response.body).toHaveProperty('version');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body.status).toBe('healthy');
  });

  test('GET /health includes uptime', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toHaveProperty('uptime');
    expect(typeof response.body.uptime).toBe('number');
  });
});