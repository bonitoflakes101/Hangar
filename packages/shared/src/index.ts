export type StackStatus =
  | 'draft'
  | 'applying'
  | 'healthy'
  | 'destroying'
  | 'errored'
  | 'destroyed';

export type RunType = 'plan' | 'apply' | 'destroy';

export type RunStatus = 'running' | 'success' | 'error' | 'cancelled';

export type NodeTypeId = 'static-site' | 'serverless-api' | 'ecs-fargate' | 'fullstack';

export interface HealthResponse {
  status: 'ok';
  service: 'hangar-server';
  timestamp: string;
}
