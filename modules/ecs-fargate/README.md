# ecs-fargate

A complete container hosting setup: a VPC with public/private subnets, an Application Load Balancer in the public subnets, and an ECS Fargate service running your container in the private subnets. Use this when you have a Dockerized long-running web app (Node, Go, Python, Java, Rails, etc.) and you do not want to manage servers or Kubernetes.

## Architecture

```
              Internet
                 │
                 ▼
     ┌─────────────────────────┐
     │   ALB (public subnets)  │  ← HTTP :80
     └────────────┬────────────┘
                  │  forward to target group
                  ▼
     ┌─────────────────────────┐
     │  ECS Fargate tasks      │
     │  (private subnets)      │  ← awsvpc, no public IP
     │  - container :80        │
     └────────────┬────────────┘
                  │ outbound only
                  ▼
            NAT Gateway → Internet
                  │
                  ▼
        CloudWatch Logs (/ecs/<name>)
```

The ALB security group only accepts :80 from the internet. The task security group only accepts traffic from the ALB. Tasks have no public IP and reach the internet through the NAT Gateway for things like image pulls and outbound API calls.

## Usage

```hcl
module "app" {
  source = "../../modules/ecs-fargate"

  name            = "my-app"
  container_image = "nginx:alpine"
  container_port  = 80
  desired_count   = 1

  container_environment = {
    LOG_LEVEL = "info"
  }

  tags = { Project = "my-app" }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| name | string | — | Resource name prefix. |
| vpc_cidr | string | `"10.10.0.0/16"` | VPC CIDR block. |
| container_name | string | `"app"` | Container name in the task definition. |
| container_image | string | `"nginx:alpine"` | Docker image including tag. |
| container_port | number | `80` | Port the container listens on. |
| container_environment | map(string) | `{}` | Env vars passed to the container. |
| task_cpu | number | `256` | Fargate CPU units (256 = 0.25 vCPU). |
| task_memory | number | `512` | Fargate memory in MiB. |
| desired_count | number | `1` | Number of running tasks. |
| health_check_path | string | `"/"` | ALB target group health check path. |
| log_retention_days | number | `7` | CloudWatch log retention. |
| tags | map(string) | `{}` | Tags applied to all resources. |

## Outputs

| Name | Description |
|---|---|
| vpc_id | VPC ID. |
| public_subnet_ids | Public subnet IDs. |
| private_subnet_ids | Private subnet IDs. |
| alb_arn | ALB ARN. |
| alb_dns_name | ALB public DNS name. |
| alb_url | Full `http://` URL of the ALB. |
| ecs_cluster_name | ECS cluster name. |
| ecs_service_name | ECS service name. |
| task_role_arn | IAM role ARN for the running container. |
| log_group_name | CloudWatch log group with container logs. |

## How to deploy and test this

### 1. Prerequisites check

```sh
terraform -version
aws --version
aws sts get-caller-identity
```

### 2. Edit the example

```sh
cd examples/ecs-fargate
```

Open `main.tf`. The default uses `nginx:alpine` so it works without you needing to push your own image. Change `name` so resources are namespaced for your account.

### 3. Init, plan, apply

```sh
terraform init
terraform plan
terraform apply       # type: yes
```

Apply takes ~5–7 minutes — most of it is the NAT Gateway and ALB warming up.

### 4. Verify

```sh
URL=$(terraform output -raw alb_url)

# The first request may 503 for ~60s while the task starts and passes health checks.
# Re-run if needed.
curl -i $URL
```

You should see the nginx welcome page (200 OK with HTML). To watch the container logs:

```sh
LOG_GROUP=$(terraform output -raw log_group_name)
aws logs tail $LOG_GROUP --follow
```

### 5. Destroy

```sh
terraform destroy     # type: yes
```

Destroy takes ~3–5 minutes. The NAT Gateway and ALB take the longest.

## Cost warning

| Service | Free tier? | Approx cost if left running 24h |
|---|---|---|
| **NAT Gateway** | **No** | ~**$1.10/day** (~$33/month) — biggest cost in this stack |
| ALB | No | ~$0.55/day (~$16/month) |
| Fargate (256 CPU / 512 MB) | No | ~$0.25/day (~$7.30/month per task) |
| VPC, subnets, IGW | Free | $0 |
| CloudWatch Logs | 5 GB/mo free for 12 months | ~$0 at low log volume |

**Total: roughly $1.90/day if left running.** Always `terraform destroy` when you finish testing.

> If you only want to keep this around for a short while, the NAT Gateway is the dominant cost. There is no way to make this architecture cheap while running — that is just AWS pricing.
