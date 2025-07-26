const request = require('supertest');
const app = require('./server'); // make sure server.js exports the app

describe('GET /', () => {
  it('should return 200 OK', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
  });
});

