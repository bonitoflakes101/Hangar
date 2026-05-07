# terraform-aws-webapp-blueprints

Reusable Terraform modules for the four AWS web-application architectures you will see most often in the real world. Each module is paired with a working `examples/` deployment so you can clone, apply, verify, and destroy in minutes.

This repo is built for **people who are new to Terraform and AWS**. Every README walks you through deploy → verify → destroy with copy-pasteable commands. The default region is `ap-southeast-1` (Singapore).

## Architectures included

| Folder | What it builds | When to use it |
|---|---|---|
| `static-site` | S3 (private) + CloudFront with Origin Access Control | Single-page apps, marketing sites, docs, anything that is just HTML/JS/CSS. |
| `ecs-fargate` | VPC + ALB + ECS Fargate service | Long-running container workloads (Node, Go, Python, Java) without managing servers. |
| `serverless-api` | Lambda + API Gateway HTTP API | Event-driven REST/JSON APIs that scale to zero when idle. |
| `fullstack` | VPC + ALB + ECS Fargate + RDS (PostgreSQL) | A typical web app with a database backing store. |

## Repository layout

```
modules/<name>/    # the reusable module — call this from your own code
examples/<name>/   # a runnable demo that calls the module above
```

This is the standard pattern used by the official `terraform-aws-modules` projects on GitHub. Modules contain only resources; examples contain real values.

## Prerequisites

Install once on your machine:

1. **Terraform >= 1.5** — https://developer.hashicorp.com/terraform/install
   ```sh
   terraform -version
   ```
2. **AWS CLI v2** — https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
   ```sh
   aws --version
   ```
3. **An AWS account** with an IAM user/role that can create the resources for the architecture you pick.

### IAM permissions per architecture

You will be safe with `AdministratorAccess` while learning. For least-privilege, the minimum services per architecture are:

| Architecture | Services your IAM principal needs |
|---|---|
| static-site | s3, cloudfront, iam (read) |
| ecs-fargate | ec2 (vpc), elasticloadbalancing, ecs, iam, logs |
| serverless-api | lambda, apigateway, iam, logs |
| fullstack | ec2 (vpc), elasticloadbalancing, ecs, rds, secretsmanager, iam, logs |

## Global quickstart

```sh
# 1. Clone
git clone https://github.com/<you>/terraform-aws-webapp-blueprints.git
cd terraform-aws-webapp-blueprints

# 2. Configure AWS credentials (interactive — paste your access key/secret)
aws configure
# Default region name [None]: ap-southeast-1
# Default output format [None]: json

# 3. Confirm the credentials work
aws sts get-caller-identity

# 4. Pick one of the four examples and follow its README
cd examples/static-site
```

## The deploy → verify → destroy loop

This is the basic loop you will repeat for every architecture in this repo. Read it once, then follow the per-architecture README for the actual values.

1. **`cd` into the example folder** for the architecture you want.
   ```sh
   cd examples/static-site
   ```
2. **Edit the placeholder values** in `main.tf`. Bucket names, app names, container images — the comments tell you what each one means.
3. **`terraform init`** — downloads the AWS provider and prepares the working directory.
   ```sh
   terraform init
   ```
4. **`terraform plan`** — shows you exactly what AWS resources will be created. **Read this output.** Understanding what gets built is the whole point of using Terraform.
   ```sh
   terraform plan
   ```
5. **`terraform apply`** — actually creates the resources. Type `yes` when prompted.
   ```sh
   terraform apply
   ```
6. **Verify it works** — every architecture README has a "How to verify" section with the exact `curl` or browser steps.
7. **`terraform destroy`** — **always do this when you are done practicing.** AWS keeps charging you for resources whether you use them or not.
   ```sh
   terraform destroy
   ```

## Cost awareness

**AWS is not free.** The free tier covers a useful subset for the first 12 months of a new account, but anything outside that incurs charges by the hour or by request.

- AWS Free Tier overview: https://aws.amazon.com/free/
- Each architecture README has a **Cost warning** section listing which resources are *not* free tier and the rough 24-hour cost if you forget to destroy.
- `terraform destroy` is your safety net. Run it. Twice if you have to.

## Troubleshooting

| Error you see | What it means | Fix |
|---|---|---|
| `Error: No valid credential sources found` | Terraform cannot find AWS credentials. | Run `aws configure`, then `aws sts get-caller-identity` to confirm. |
| `Error acquiring the state lock` | A previous Terraform run did not finish cleanly and left a lock behind. | Delete the local `.terraform.lock.hcl` and retry. If using a remote S3+DynamoDB backend, run `terraform force-unlock <LOCK_ID>` (the ID is in the error message). |
| `InvalidClientTokenId: The security token included in the request is invalid` | Wrong region, expired credentials, or typo'd access key. | Re-run `aws configure`. Confirm region with `aws configure get region`. |
| `BucketAlreadyExists` / S3 bucket name already taken | S3 bucket names are **globally unique across all of AWS**. | Edit the example and pick a more unique name (add your username, a date, etc.). |
| RDS takes 5–10 minutes to destroy | Normal. RDS shutdown is slow. | Wait it out. Do not Ctrl+C `terraform destroy`. |
| `Error creating ECS service: unable to assume role` | IAM role propagation delay on first apply. | Wait ~30 seconds and run `terraform apply` again. |

## License

MIT — use this however you like. No warranty.
