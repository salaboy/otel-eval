const express = require('express');

const app = express();
const port = process.env.PORT || 3000;
const serviceName = process.env.OTEL_SERVICE_NAME || 'otel-eval-backend';

app.use(express.json());

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

app.get('/', (req, res) => {
  res.json({
    service: serviceName,
    message: 'Hello from the evaluation backend!',
    timestamp: new Date().toISOString(),
    headers: {
      traceparent: req.headers['traceparent'],
      tracestate: req.headers['tracestate'],
      'x-forwarded-for': req.headers['x-forwarded-for'],
      'x-real-ip': req.headers['x-real-ip']
    }
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`${serviceName} listening on port ${port}`);
});
