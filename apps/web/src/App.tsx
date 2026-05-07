import { useEffect, useState } from 'react';
import type { HealthResponse } from '@hangar/shared';

export function App() {
  const [health, setHealth] = useState<HealthResponse | { error: string } | null>(null);

  useEffect(() => {
    fetch('/api/health')
      .then((r) => r.json())
      .then(setHealth)
      .catch((e: Error) => setHealth({ error: e.message }));
  }, []);

  return (
    <main>
      <h1>Hangar</h1>
      <p>scaffolding online</p>
      <h2>server health</h2>
      <pre>{health ? JSON.stringify(health, null, 2) : 'checking…'}</pre>
    </main>
  );
}
