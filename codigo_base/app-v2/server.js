const express = require('express');
const app = express();
const PORT = 8080;

const ENV_NAME = process.env.APP_ENV || 'CANARY';
const VERSION = process.env.APP_VERSION || '2.0.0';
const COLOR = process.env.APP_COLOR || '#D97706';

// Variable para simulación de inyección de fallos en caliente
let faultInjected = false;

app.post('/api/fault/enable', (req, res) => {
  faultInjected = true;
  console.log(`[CANARY ALERTA] Fallo inyectado. Respondiendo HTTP 500.`);
  res.json({ faultStatus: 'ENABLED', message: 'Inyección de errores HTTP 500 activada' });
});

app.post('/api/fault/disable', (req, res) => {
  faultInjected = false;
  console.log(`[CANARY RESTAURADO] Fallo desactivado. Salud normal.`);
  res.json({ faultStatus: 'DISABLED', message: 'Inyección de errores desactivada' });
});

app.get('/api/health', (req, res) => {
  if (faultInjected) {
    return res.status(500).json({ status: 'DOWN', error: 'Database Pool Exhaustion', environment: ENV_NAME });
  }
  res.json({ status: 'UP', version: VERSION, environment: ENV_NAME });
});

app.get('/api/info', (req, res) => {
  if (faultInjected) {
    return res.status(500).json({ error: 'Internal Server Error 500: Fallo en Canary' });
  }
  res.json({
    status: 'ACTIVE',
    environment: ENV_NAME,
    version: VERSION,
    color: COLOR,
    canaryFeatures: ['Algoritmo de recomendación v2', 'Compresión Brotli'],
    timestamp: new Date().toISOString()
  });
});

app.get('/', (req, res) => {
  if (faultInjected) {
    return res.status(500).send('HTTP 500 Internal Server Error en Canary');
  }
  res.send(`
    <html>
      <body style="background-color: ${COLOR}; color: white; font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0;">
        <div style="text-align: center; padding: 2rem; border-radius: 12px; background: rgba(0,0,0,0.3);">
          <h1>Entorno Canary: ${ENV_NAME}</h1>
          <p>Nueva Versión en Evaluación: <strong>${VERSION}</strong></p>
          <p>Cuota de Tráfico: 10% de Usuarios</p>
        </div>
      </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`[CANARY v${VERSION}] Iniciado en puerto ${PORT}`);
});
