const request = require('supertest');
const app = require('../src/index');

describe('API Endpoints', () => {
  describe('GET /', () => {
    test('returns welcome message', async () => {
      const response = await request(app).get('/');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('endpoints');
    });
  });

  describe('GET /api/info', () => {
    test('returns API information', async () => {
      const response = await request(app).get('/api/info');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('api');
      expect(response.body).toHaveProperty('version');
    });
  });

  describe('Users API', () => {
    test('GET /api/users returns user list', async () => {
      const response = await request(app).get('/api/users');
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    test('GET /api/users/:id returns specific user', async () => {
      const response = await request(app).get('/api/users/1');
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id', 1);
      expect(response.body.data).toHaveProperty('name');
    });

    test('GET /api/users/:id returns 404 for non-existent user', async () => {
      const response = await request(app).get('/api/users/999');
      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });

    test('POST /api/users creates new user', async () => {
      const newUser = {
        name: 'Test User',
        email: 'test@example.com',
        role: 'user'
      };

      const response = await request(app)
        .post('/api/users')
        .send(newUser);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data.name).toBe(newUser.name);
    });

    test('POST /api/users requires name and email', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({ name: 'Only Name' });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe('Tasks API', () => {
    test('GET /api/tasks returns task list', async () => {
      const response = await request(app).get('/api/tasks');
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    test('GET /api/tasks supports status filter', async () => {
      const response = await request(app).get('/api/tasks?status=completed');
      expect(response.status).toBe(200);
      expect(response.body.data.every(t => t.status === 'completed')).toBe(true);
    });

    test('GET /api/tasks/:id returns specific task', async () => {
      const response = await request(app).get('/api/tasks/1');
      expect(response.status).toBe(200);
      expect(response.body.data).toHaveProperty('id', 1);
    });

    test('POST /api/tasks creates new task', async () => {
      const newTask = {
        title: 'Test Task',
        priority: 'high'
      };

      const response = await request(app)
        .post('/api/tasks')
        .send(newTask);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe(newTask.title);
      expect(response.body.data.status).toBe('pending');
    });

    test('PATCH /api/tasks/:id updates task', async () => {
      const updates = {
        status: 'completed'
      };

      const response = await request(app)
        .patch('/api/tasks/1')
        .send(updates);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('completed');
    });
  });

  describe('404 Handler', () => {
    test('returns 404 for unknown routes', async () => {
      const response = await request(app).get('/unknown-route');
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
    });
  });
});