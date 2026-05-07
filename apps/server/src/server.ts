import Fastify from 'fastify';
import cors from '@fastify/cors';
import type { HealthResponse } from '@hangar/shared';

const app = Fastify({ logger: { level: 'info' } });

await app.register(cors, { origin: 'http://localhost:5173' });

app.get('/api/health', async (): Promise<HealthResponse> => ({
  status: 'ok',
  service: 'hangar-server',
  timestamp: new Date().toISOString(),
}));

const port = Number(process.env.PORT ?? 4000);
await app.listen({ port, host: '127.0.0.1' });
