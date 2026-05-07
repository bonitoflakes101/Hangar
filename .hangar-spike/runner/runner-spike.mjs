// Runner spike — prove the terraform shell-out + streaming + plan-JSON parse pipeline
// before committing to the real runner abstraction in apps/server.
//
// Usage: node runner-spike.mjs [stack-dir]
// Default stack dir: ../sniff/static-site (already init'd)

import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const STACK_DIR = resolve(__dirname, process.argv[2] ?? '../sniff/static-site');

function streamRun(args) {
  return new Promise((res, rej) => {
    const start = Date.now();
    let lineCount = 0;
    let lastLineAt = start;
    let maxGap = 0;

    const child = spawn('terraform', args, {
      cwd: STACK_DIR,
      env: { ...process.env, TF_IN_AUTOMATION: '1', TF_INPUT: '0' },
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    const onLine = (stream) => (line) => {
      const now = Date.now();
      const gap = now - lastLineAt;
      if (gap > maxGap) maxGap = gap;
      lastLineAt = now;
      lineCount++;
      const t = ((now - start) / 1000).toFixed(2).padStart(6);
      console.log(`[${t}s ${stream}] ${line}`);
    };

    createInterface({ input: child.stdout }).on('line', onLine('out'));
    createInterface({ input: child.stderr }).on('line', onLine('err'));

    child.on('close', (code) => {
      const elapsed = ((Date.now() - start) / 1000).toFixed(2);
      console.log(`\n>>> exit=${code}  elapsed=${elapsed}s  lines=${lineCount}  max_inter_line_gap=${maxGap}ms\n`);
      code === 0 ? res({ code, elapsed, lineCount, maxGap }) : rej(new Error(`exit ${code}`));
    });
  });
}

function captureRun(args) {
  return new Promise((res, rej) => {
    let buf = '';
    const child = spawn('terraform', args, {
      cwd: STACK_DIR,
      env: { ...process.env, TF_IN_AUTOMATION: '1', TF_INPUT: '0' },
    });
    child.stdout.on('data', (d) => (buf += d));
    child.on('close', (code) => (code === 0 ? res(buf) : rej(new Error(`exit ${code}`))));
    child.on('error', rej);
  });
}

console.log(`=== STACK_DIR: ${STACK_DIR} ===\n`);

console.log('=== STEP 1: terraform plan (streaming) ===');
const planResult = await streamRun(['plan', '-no-color', '-input=false', '-out=plan.tfplan']);

console.log('=== STEP 2: terraform show -json (capture for parse) ===');
const planJsonStr = await captureRun(['show', '-json', 'plan.tfplan']);
const planJson = JSON.parse(planJsonStr);

const summary = { add: 0, change: 0, destroy: 0, replace: 0, read: 0, other: 0 };
for (const rc of planJson.resource_changes ?? []) {
  const a = rc.change.actions;
  const key = a.includes('create') && a.includes('delete')
    ? 'replace'
    : a[0] === 'create' ? 'add'
    : a[0] === 'update' ? 'change'
    : a[0] === 'delete' ? 'destroy'
    : a[0] === 'read' ? 'read'
    : 'other';
  summary[key]++;
}

console.log('=== STEP 3: parsed plan summary ===');
console.log(JSON.stringify(summary, null, 2));
console.log(`\nresource_changes total: ${planJson.resource_changes?.length ?? 0}`);
console.log(`output_changes total:   ${Object.keys(planJson.output_changes ?? {}).length}`);

console.log('\n=== streaming health ===');
console.log(`plan elapsed:        ${planResult.elapsed}s`);
console.log(`lines streamed:      ${planResult.lineCount}`);
console.log(`max inter-line gap:  ${planResult.maxGap}ms`);
console.log(planResult.maxGap < 5000
  ? '✓ streaming healthy (< 5s gap)'
  : '⚠ streaming may be buffering — investigate');
