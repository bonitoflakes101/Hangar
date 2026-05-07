# Hangar — Implementation Plan

**Status:** §7 pre-flight complete (modules sniff-tested, runner spike validated). Ready to scaffold.
**Last updated:** 2026-05-07
**Scope:** Personal-use tool for the repo owner. Single-user, single-machine, local-first. Not a product.

---

## What we're building

A local web app that gives a drag-and-drop UI over Terraform for spinning up, managing, and tearing down AWS sandbox stacks. Built on top of the existing composite modules in `modules/` (`static-site`, `ecs-fargate`, `serverless-api`, `fullstack`).

**Primary value:** speed up the user's daily cloud-engineering work — fast sandbox creation, automatic teardown via TTL (no more forgotten stacks), one place to see all running stacks and their cost.

## Locked decisions

| Decision | Choice | Reason |
|---|---|---|
| Audience | Personal tool, just for the user | Kills multi-tenant, billing, onboarding concerns |
| Frontend | Vite + React + React Flow + shadcn/ui + Tailwind + Zustand | Local app, no SSR overhead, fastest iteration |
| Backend | Fastify (Node) + better-sqlite3 + node-cron | Simple, sync SQLite API, terraform shell-out via child_process |
| State backend | Local files under `~/.hangar/` | User chose local; S3 backend can come later |
| TTL on apply failure | Pause TTL, mark `errored`, leave state for inspection | Auto-destroy on failure deletes evidence you need to debug |
| v1 palette | 4 composite-module nodes (use existing `modules/`) | Terraform work already done; first working stack in 1 weekend instead of 3 |
| Atomic palette + smart edges | v2 | Pipeline must be proven before building the interesting compiler work |
| Drift detection | On-demand button only in v1 | Scheduled drift checks add complexity for low daily payoff |
| Cost view | Folded into Stacks dashboard header | Separate screen overkill for one user |

## Strategic shift from earlier brainstorm

Original plan was 15 atomic-resource nodes (VPC, ALB, RDS, …) with smart edges auto-wiring IAM/SG/target-groups. Discovering the existing `modules/` directory changed that:

| | Original v1 (atomic) | Revised v1 (composite) |
|---|---|---|
| Palette | 15 atomic nodes | 4 composite nodes mapping to existing modules |
| Terraform work | Author 15 modules from scratch | Already done |
| Compiler | Smart edges, dependency wiring, IAM auto-gen | Trivial — one `module "x"` block per node |
| Risk | High | Low |
| Time to first working stack | ~2 weeks | ~1 weekend |

The atomic palette + smart-edge work moves to v2 once the lifecycle pipeline (compile → plan → apply → state → destroy → cost) is proven.

---

## 1. Repo layout

Existing `modules/` and `examples/` stay untouched. Add the app alongside as a npm workspace.

```
Hangar/
├── modules/                    # existing — unchanged
│   ├── static-site/
│   ├── ecs-fargate/
│   ├── serverless-api/
│   └── fullstack/
├── examples/                   # existing — unchanged, still useful as reference
├── apps/
│   ├── web/                    # Vite + React + React Flow + shadcn/ui
│   │   ├── src/
│   │   │   ├── views/          # Stacks, Editor, Recipes, Settings
│   │   │   ├── canvas/         # React Flow setup, custom node components
│   │   │   ├── inspector/      # forms per node type
│   │   │   ├── api/            # client for server (typed via shared)
│   │   │   ├── store/          # Zustand
│   │   │   └── main.tsx
│   │   ├── index.html
│   │   ├── vite.config.ts
│   │   └── package.json
│   └── server/                 # Fastify backend
│       ├── src/
│       │   ├── routes/         # /stacks, /runs, /recipes, /settings
│       │   ├── db/             # SQLite (better-sqlite3) + migrations
│       │   ├── terraform/      # spawn, log streaming, state parsing
│       │   ├── compiler/       # graph → main.tf
│       │   ├── modules/        # node-type → module-source registry
│       │   ├── jobs/           # node-cron TTL sweeper, cost refresh
│       │   ├── aws/            # profile discovery, Cost Explorer
│       │   └── server.ts
│       └── package.json
├── packages/
│   └── shared/                 # TS types shared between web and server
├── npm-workspace.yaml
├── package.json
├── tsconfig.base.json
├── PLAN.md                     # this file
└── README.md                   # existing modules' README
```

User-data location (outside the repo):

```
~/.hangar/
├── db.sqlite
├── config.json                 # global settings (profiles, tag defaults)
└── stacks/
    └── <stack-id>/
        ├── graph.json          # canvas state — single source of truth
        ├── main.tf             # generated from graph
        ├── terraform.tf        # provider + backend
        ├── terraform.tfstate   # local state
        ├── .terraform/
        └── runs/
            ├── 2026-05-08T...-plan.log
            └── 2026-05-08T...-apply.log
```

The canvas (`graph.json`) is the canonical representation. `main.tf` is regenerated from it on every plan. No drift between UI and HCL is possible.

---

## 2. Data model

### SQLite schema

```sql
CREATE TABLE stacks (
  id              TEXT PRIMARY KEY,           -- ulid
  name            TEXT NOT NULL,              -- AWS tag-safe
  profile         TEXT NOT NULL,              -- AWS_PROFILE
  region          TEXT NOT NULL,
  status          TEXT NOT NULL,              -- draft|applying|healthy|destroying|errored|destroyed
  ttl_at          INTEGER,                    -- unix seconds; null = no TTL
  ttl_paused      INTEGER NOT NULL DEFAULT 0, -- 1 when stack is errored
  current_run_id  TEXT,                       -- non-null = locked
  last_apply_at   INTEGER,
  outputs_json    TEXT,                       -- terraform output -json cached
  created_at      INTEGER NOT NULL,
  updated_at      INTEGER NOT NULL
);

CREATE TABLE runs (
  id           TEXT PRIMARY KEY,              -- ulid
  stack_id     TEXT NOT NULL REFERENCES stacks(id),
  type         TEXT NOT NULL,                 -- plan|apply|destroy
  status       TEXT NOT NULL,                 -- running|success|error|cancelled
  started_at   INTEGER NOT NULL,
  finished_at  INTEGER,
  exit_code    INTEGER,
  log_path     TEXT NOT NULL,                 -- relative to stack dir
  summary_json TEXT                           -- parsed plan: adds/changes/destroys
);

CREATE INDEX idx_runs_stack ON runs(stack_id, started_at DESC);

CREATE TABLE cost_cache (
  stack_id     TEXT NOT NULL REFERENCES stacks(id),
  fetched_at   INTEGER NOT NULL,
  daily_json   TEXT NOT NULL,                 -- daily breakdown for last 7d
  PRIMARY KEY (stack_id)
);
```

No `recipes` table in v1 — composite modules *are* the recipes.

### Canvas representation (`graph.json`)

```json
{
  "version": 1,
  "stack": { "id": "01H...", "name": "repro-4421", "region": "ap-southeast-1" },
  "nodes": [
    {
      "id": "n_main",
      "type": "fullstack",
      "position": { "x": 200, "y": 200 },
      "data": {
        "name": "main",
        "vars": {
          "vpc_cidr": "10.42.0.0/16",
          "container_image": "...",
          "db_instance_class": "db.t4g.small"
        }
      }
    }
  ],
  "edges": []
}
```

In v1, edges are empty — composite-module nodes are independent. v2 introduces `kind` on edges with the smart-edge registry.

---

## 3. Build order

Each milestone ends with something **end-to-end functional**, not "infrastructure for the next milestone."

### Weekend 1 — vertical slice: dashboard + apply/destroy a `static-site`

Goal: open Hangar, click "+ New stack → Static Site", configure the bucket name, hit Apply, see it on AWS, hit Destroy, see it gone.

**Server**
- npm workspace, Fastify + tsx-watch for dev
- SQLite migrations runner
- `POST /stacks` — create stack row + scaffold filesystem dir + write minimal `graph.json` and `terraform.tf` (provider + local backend)
- `POST /stacks/:id/runs` — body `{ type: plan | apply | destroy }`, spawns terraform, streams logs to file, updates run row
- `GET /stacks/:id/runs/:runId/stream` — SSE endpoint replaying log + tailing
- Compiler module: `static-site` node → emits `module "main" { source = "..." ; ... }`
- Profile discovery from `~/.aws/config`

**Web**
- App shell (left rail nav, top bar with profile/region selectors)
- Stacks dashboard (list, "+ New stack" with one option: static-site)
- Editor view with React Flow but only **one** node type rendered + Inspector form for static-site vars
- Plan / Apply / Destroy buttons, output drawer with SSE consumption
- Stack status polling every 2s while a run is active

**Exit criterion:** real S3+CloudFront stack created and destroyed via the UI. Pipeline proven.

### Weekend 2 — fill out the four composites + lifecycle features

**Server**
- Node-type registry: `static-site` / `serverless-api` / `ecs-fargate` / `fullstack`. Each maps to a module path, an inspector schema (JSON-schema for inputs), and a default vars set.
- Plan summary parser — parse `terraform show -json plan.out` to extract add/change/destroy counts and per-resource actions.
- Outputs cache — after apply, run `terraform output -json`, store on stack row.
- Run-lock enforcement on all mutating endpoints.
- Errored-stack pause: when a run exits non-zero, set `ttl_paused=1`, status `errored`.

**Web**
- Inspector forms for the other three node types (auto-rendered from JSON schema with shadcn/ui form components).
- Plan-diff overlay on the canvas: after a successful plan, node borders color green/yellow/red based on module-scoped diff.
- Outputs panel (right drawer) appearing after apply, copy buttons per output.
- Run lock UI (greyed canvas + "running" overlay during a run).
- Errored-stack recovery actions on the dashboard row.

**Exit criterion:** all four composite stacks usable end-to-end. Errors handled gracefully. The tool is daily-driver useful.

### Weekend 3 — TTL, costs, settings, polish

**Server**
- node-cron job every 5 min: select stacks where `ttl_at < now() AND status='healthy' AND ttl_paused=0`, kick destroy run.
- Cost Explorer integration — `@aws-sdk/client-cost-explorer`, filter by `tag:ManagedBy=hangar` group by `tag:Stack`. Cache 1h.
- Stale-lock detection on stack-dir reads — if `.terraform.tfstate.lock.info` exists but no terraform pid, offer reset.
- Settings endpoints: `/settings`, `/profiles`.

**Web**
- TTL picker in editor toolbar (1h/4h/8h/24h/never), TTL countdown on dashboard rows, in-app banner when <30 min remaining.
- Costs strip on dashboard header (today's total, this month) + "Forgotten stacks" callout (>24h, no TTL).
- Run history tab inside editor (list of runs with click-to-replay log).
- Settings screen (default profile, default region, default tags, default TTL).
- Command palette (`⌘K`) — fuzzy over: switch stack, new from type, plan/apply/destroy, settings.
- Empty states, loading states, error toasts.

**Exit criterion:** shippable to self. Daily use begins.

### Buffer / phase-1.5

- Diagram export (PNG/SVG via React Flow's `toImage`)
- On-demand "Check drift" button per stack
- Stack rename + clone
- Performance pass on canvas (memo node components)

### v2 backlog (out of scope for this plan)

- Atomic-resource palette (15-node set: VPC, Subnet, SG, Route53 Record, ALB, CloudFront, API Gateway, ECS Service, Lambda, EC2, RDS, DynamoDB, S3, IAM Role, SQS) authored as new modules under `modules/atomic/`
- Smart-edge registry with the ~10 connection rules (Lambda→DynamoDB IAM, ALB→ECS target group, etc.)
- Recipes table (save canvas selections as reusable subgraphs)
- Import existing AWS account → diagram (via `terraformer`)
- Deploy-local-code PaaS layer

---

## 4. Core abstractions

### Node-type registry (`apps/server/src/modules/registry.ts`)

```ts
type NodeTypeSpec = {
  id: 'static-site' | 'ecs-fargate' | 'serverless-api' | 'fullstack';
  modulePath: string;              // absolute path resolved at runtime
  displayName: string;
  iconKey: string;
  inputs: JSONSchema7;             // drives the inspector form
  defaults: Record<string, unknown>;
  outputsToSurface: string[];      // which terraform outputs to highlight in UI
};
```

Single TS object imported by both server and web via `packages/shared`. Adding v2 atomic nodes is purely "add an entry here + write the module."

### Compiler (`apps/server/src/compiler/`)

For v1, intentionally trivial:

```ts
function compile(graph: Graph, stack: Stack): { mainTf: string; terraformTf: string } {
  const moduleBlocks = graph.nodes.map(node => {
    const spec = registry[node.type];
    return renderModuleBlock(node.data.name, spec.modulePath, node.data.vars);
  });
  return {
    mainTf: moduleBlocks.join('\n\n'),
    terraformTf: renderProviderAndBackend(stack.region),
  };
}
```

`renderModuleBlock` is template-string HCL emission. Strings escaped via `JSON.stringify` (works for HCL too); numbers/bools passthrough; maps/lists recursive. Snapshot tests against golden files from day one.

**fmt post-pass:** after `compile()`, run `terraform fmt -write=true main.tf` in the stack dir. This gives canonical HCL formatting for free and removes the burden of perfect alignment in the templater. (Confirmed in §7.5 — `terraform fmt` flagged only cosmetic whitespace on the spike-generated files, no syntax issues.)

In v2 the compiler grows: topo sort, smart-edge passes, IAM/SG injection.

### Terraform runner (`apps/server/src/terraform/runner.ts`)

```ts
async function run(stackDir: string, args: string[], opts: { profile, region }): Promise<RunResult>
```

- `child_process.spawn('terraform', args, { cwd: stackDir, env: { ...process.env, AWS_PROFILE, AWS_REGION, TF_IN_AUTOMATION: '1', TF_INPUT: '0' } })`
- Pipe stdout+stderr through a line-splitter, write each line to log file AND emit on an EventEmitter keyed by run-id.
- `-no-color` for parsing; UI re-applies its own coloring.
- Exit code → run row `status` + `exit_code`.

SSE endpoint subscribes to that EventEmitter for live logs, falls back to log-file read for completed/cancelled runs.

### Status reconciliation

After every successful apply: `terraform output -json` → cache JSON on stack row. Sufficient for v1 (we surface outputs in the UI; canvas just needs node-level "healthy" status from the run succeeding). v2 adds per-resource state mapping for fine-grained drift highlights.

### TTL background job

```ts
cron.schedule('*/5 * * * *', async () => {
  const expired = db.prepare(`
    SELECT id FROM stacks
    WHERE status = 'healthy' AND ttl_paused = 0
      AND ttl_at IS NOT NULL AND ttl_at < ?
  `).all(now());
  for (const { id } of expired) await enqueueDestroy(id, { reason: 'ttl' });
});
```

Destroys go through the same run pipeline; the dashboard surfaces them as a normal destroy run with `reason: ttl`.

### AWS profile handling

Don't read credentials directly; let terraform's AWS provider chain handle SSO/role-chain/IMDS. Server only:
- Parses `~/.aws/config` and `~/.aws/credentials` to enumerate profile *names* for the picker.
- Sets `AWS_PROFILE` and `AWS_REGION` on spawn.
- Detects expired SSO via stderr pattern (`SSO session has expired`) and surfaces a "Run `aws sso login --profile X`" hint.

---

## 5. Terraform work required

**For v1: zero new modules.** The existing four composites are the v1 palette.

**Update from §7.5: all three originally-planned touch-ups are unnecessary.** Confirmed by sniff test:

1. ~~Add `ManagedBy/Stack/Owner` to default tags~~ — every module already accepts a `tags` map that propagates to all resources. Compiler passes `{ManagedBy, Stack, Owner, Environment}` through `tags`. No module edits needed.
2. ~~Add outputs to surface in UI~~ — already present: `cloudfront_url` (static-site), `api_endpoint` (serverless-api), `alb_url` (ecs-fargate), `alb_url`/`db_endpoint`/`db_secret_arn`/`db_secret_name` (fullstack).
3. ~~Confirm unique-name input~~ — every module takes `name` (or `bucket_name` for static-site) as a prefix. Compiler passes the stack id.

**Net effect:** the Terraform side is already production-ready for v1. All weekend-1/2/3 effort is pure app code.

**For v2:** the 15 atomic modules — separate planning exercise.

---

## 6. Risks to validate early

In rough order of "I'd test this in week 1":

1. **Terraform output streaming on macOS.** Line-buffering can hold output back for minutes. Validate by running an actual `apply` against AWS through the runner and watching live log latency. If chunks lag, confirm `TF_IN_AUTOMATION=1` is enough; `unbuffer` isn't on macOS by default. **✓ Mitigated 2026-05-07** — runner spike streamed 246 lines for `terraform plan` with max inter-line gap 2.2s (within tolerance, attributable to AWS state-refresh pause). `TF_IN_AUTOMATION=1 TF_INPUT=0 -no-color` suffices, no `unbuffer` needed.

2. **HCL emission edge cases.** Strings with quotes/backticks/newlines, sensitive vars, maps with mixed types. Mitigation: snapshot/golden tests for the compiler from day one (`tests/compiler/static-site.golden.tf`). Run `terraform fmt -check` against compiler output.

3. **Module path resolution.** Generated `main.tf` lives at `~/.hangar/stacks/<id>/main.tf`. `source = "../../modules/static-site"` won't resolve there. **Decision: absolute paths with a `HANGAR_MODULES_DIR` configured at first run.** No symlinks. Validate in week 1. **✓ Mitigated 2026-05-07** — all four composite modules init+plan cleanly when called via absolute path from a scratch dir at `.hangar-spike/sniff/<module>/`. Approach is confirmed.

4. **AWS credential chain with SSO.** SSO sessions expire mid-apply. Test with a real SSO profile, let it expire, confirm the UI surfaces a useful error (not just an exit code).

5. **Stale state lock after crash.** Local backend leaves `.terraform.tfstate.lock.info` if the process dies. Server detects on stack open: lock file exists but no terraform process matches its PID → offer "Clear stale lock" instead of failing every run.

6. **React Flow performance.** Low risk in v1 (composite nodes = ≤5 nodes per stack). Validate in v2 when atomic palette lands.

7. **Cost Explorer auth + cost.** First call may fail if CE not enabled in account. Each call costs $0.01. Cache aggressively (1h). Validate by hitting once from a script in week 1.

8. **Multi-region tag-based cost grouping.** Cost Explorer groups across regions for tagged costs — should "just work" — but test with a non-default-region stack before relying on it.

---

## 7. Pre-flight: do these before writing any code

Two sanity checks, ~1 hour each, save a lot of pain later:

### Check 1 — Module sniff test
From a scratch dir, write 4 hand-written `main.tf` files calling each composite module with the inputs Hangar will pass (incl. the new tag vars). `terraform plan` each one. Confirm:
- They all init/plan cleanly with default inputs
- Tag vars wire through to actual resources
- Outputs you want to surface exist

Any gaps become the touch-up list before week-1 coding starts.

### Check 2 — End-to-end runner spike
A 50-line Node script that spawns `terraform plan` + `apply` + `destroy` against the static-site module, streams output to stdout, parses the plan JSON. If this works clean in 2 hours, the runner abstraction is low-risk. If it doesn't, you've found weekend 1's hardest problem before committing to architecture.

---

## 7.5 Pre-flight results (2026-05-07)

### Check 1 — Module sniff test: PASSED

| Module | init | plan | resources | tags wire through | outputs resolve |
|---|---|---|---|---|---|
| static-site | ✓ | ✓ | 7 | ✓ | ✓ |
| serverless-api | ✓ | ✓ | 10 | ✓ | ✓ |
| ecs-fargate | ✓ | ✓ | 26 | ✓ | ✓ |
| fullstack | ✓ | ✓ | 38 | ✓ | ✓ |

All four init'd cleanly using absolute module paths. Tags map (`ManagedBy/Stack/Owner/Environment`) propagated to every resource (verified in `tags_all` of plan output). All target outputs resolve.

### Check 2 — Runner spike: PASSED

Plan against `static-site` via `child_process.spawn`:

- elapsed: **2.39s**
- lines streamed: **246**
- max inter-line gap: **2.2s** (well under 5s threshold)
- exit code captured cleanly
- `terraform show -json plan.tfplan` parsed; classifier produced `{add: 7, change: 0, destroy: 0, replace: 0, read: 1}` — matches the human plan output.

Reference implementation lives at `.hangar-spike/runner/runner-spike.mjs` and can be lifted into `apps/server/src/terraform/runner.ts` largely as-is.

### Plan-summary classifier (canonical action shapes)

`resource_changes[].change.actions` takes these forms:

| Actions array | Bucket |
|---|---|
| `["create"]` | add |
| `["update"]` | change |
| `["delete"]` | destroy |
| `["delete", "create"]` | replace |
| `["read"]` | read (data sources — exclude from diff coloring) |
| `["no-op"]` | unchanged (exclude) |

### Action items consumed by these results

- §5 Terraform touch-ups: **all unnecessary**, struck through above
- §4 Compiler: added `terraform fmt -write` post-pass note
- §6.1, §6.3: marked mitigated above
- Weekend-1 scope shrinks slightly (no module edits to do)

## 8. Concrete next step

§7 pre-flight is **done**. Next: scaffold the npm workspace + Fastify health endpoint + Vite app shell — the first 90 min of weekend 1.

## Open questions / deferred decisions

- **Diagram export format priority:** PNG only in v1.5, or also draw.io XML? (Punt; decide when feature is built.)
- **Whether to auto-commit generated HCL to a git repo per stack.** Nice for history but adds coupling. Punt to v2.
- **Recipe parameterization model in v2.** Recipes are graph subsets but need parameter overrides on drop. Underspecified; revisit when starting v2.
