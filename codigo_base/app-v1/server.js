const express = require('express');
const app = express();
const PORT = 8080;

const ENV_NAME = process.env.APP_ENV || 'STABLE';
const VERSION = process.env.APP_VERSION || '1.0.0';
const COLOR = process.env.APP_COLOR || '#1E3A8A';

app.get('/api/health', (req, res) => {
  res.json({ status: 'UP', version: VERSION, environment: ENV_NAME });
});

app.get('/api/info', (req, res) => {
  res.json({
    status: 'ACTIVE',
    environment: ENV_NAME,
    version: VERSION,
    color: COLOR,
    timestamp: new Date().toISOString()
  });
});

app.get('/', (req, res) => {
  res.send(`
    <html>
      <body style="background-color: ${COLOR}; color: white; font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0;">
        <div style="text-align: center; padding: 2rem; border-radius: 12px; background: rgba(0,0,0,0.3);">
          <h1>Entorno Stable: ${ENV_NAME}</h1>
          <p>Versión en Producción: <strong>${VERSION}</strong></p>
          <p>90% del Tráfico de Usuarios</p>
        </div>
      </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`[STABLE v${VERSION}] Iniciado en puerto ${PORT}`);
});
